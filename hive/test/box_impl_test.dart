import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

BoxImpl getBox({
  String name,
  bool lazy,
  StorageBackend backend,
  ChangeNotifier notifier,
  Map<String, BoxEntry> entries,
  CompactionStrategy cStrategy,
}) {
  return BoxImpl.debug(
      HiveImpl(),
      name ?? 'testBox',
      BoxOptions(
        lazy: lazy ?? false,
        compactionStrategy: cStrategy ?? (total, deleted) => false,
      ),
      backend ?? BackendMock(),
      entries ?? {},
      notifier);
}

void main() {
  group('BoxImpl', () {
    test('path', () {
      var backend = BackendMock();
      when(backend.path).thenReturn('some/path');
      var box = getBox(backend: backend);
      expect(box.path, 'some/path');
    });

    test('.keys', () {
      var entries = {
        'key1': const BoxEntry(null, 0, 0),
        'key2': const BoxEntry(null, 0, 0),
        'key4': const BoxEntry(null, 0, 0)
      };
      var box = getBox(entries: entries);
      expect(box.keys, ['key1', 'key2', 'key4']);
    });

    group('.get()', () {
      test('returns defaultValue if key does not exist', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend);

        expect(await box.get('someKey'), null);
        expect(await box.get('otherKey', defaultValue: -12), -12);
        verifyZeroInteractions(backend);
      });

      test('returns lazy value if it exists', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend, entries: {
          'testKey': const BoxEntry('testVal', null, null),
        });

        reset(backend);
        expect(await box.get('testKey'), 'testVal');
        verifyZeroInteractions(backend);
      });

      test('reads value from backend', () async {
        var backend = BackendMock();
        when(backend.readValue(any, any, any))
            .thenAnswer((i) async => 'testVal');
        var box = getBox(
          lazy: true,
          backend: backend,
          entries: {'testKey': const BoxEntry('testVal', 123, 456)},
        );

        expect(await box.get('testKey'), 'testVal');
        verify(backend.readValue('testKey', 123, 456));
      });
    });

    group('[]', () {
      test('returns lazy value', () {
        var box = getBox(entries: {'key': const BoxEntry('value', 0, 0)});
        expect(box['key'], 'value');
        expect(box['nonexistantKey'], null);
      });

      test('throws if box not lazy', () {
        var box = getBox(lazy: true, entries: {});
        expect(() => box['key'], throwsHiveError('lazy boxes'));
      });
    });

    test('.has()', () {
      var backend = BackendMock();
      var box = getBox(
        backend: backend,
        entries: {'existingKey': const BoxEntry(null, null, null)},
      );

      expect(box.has('existingKey'), true);
      expect(box.has('nonExistingKey'), false);
      verifyZeroInteractions(backend);
    });

    group('.put()', () {
      BackendMock getWriteFrameMock() {
        var backend = BackendMock();
        when(backend.writeFrame(any, any))
            .thenAnswer((i) async => const BoxEntry(null, null, null));
        return backend;
      }

      test('writeFrame', () async {
        var backend = getWriteFrameMock();
        var entries = <String, BoxEntry>{};
        var box = getBox(backend: backend, entries: entries);

        await box.put('key1', null);
        verifyZeroInteractions(backend);

        await box.put('key1', 'value1');
        expect(entries.containsKey('key1'), true);
        verify(backend.writeFrame(const Frame('key1', 'value1'), false));

        await box.put('key1', null);
        expect(entries.containsKey('key1'), false);
      });

      test('compaction', () async {
        var backend = getWriteFrameMock();
        var entries = 0;
        var deletedEntries = 0;
        var shouldCompact = false;
        var box = getBox(
          backend: backend,
          cStrategy: (e, d) {
            entries = e;
            deletedEntries = d;
            return shouldCompact;
          },
        );

        await box.put('key1', null);
        expect(entries, 0);
        expect(deletedEntries, 0);

        await box.put('key1', 'value1');
        expect(entries, 1);
        expect(deletedEntries, 0);

        await box.put('key1', 'value2');
        expect(entries, 1);
        expect(deletedEntries, 1);

        await box.put('key1', null);
        expect(entries, 0);
        expect(deletedEntries, 2);

        verifyNever(backend.compact(any));
        shouldCompact = true;

        await box.put('key1', 'abc');
        expect(entries, 1);
        expect(deletedEntries, 2);
        verify(backend.compact({'key1': const BoxEntry(null, null, null)}));
      });
    });

    group('.putAll()', () {
      BackendMock getWriteFramesMock() {
        var backend = BackendMock();
        when(backend.writeFrames(any, false)).thenAnswer((i) async {
          return List.filled((i.positionalArguments[0] as List).length,
              const BoxEntry(null, null, null));
        });
        return backend;
      }

      test('writeFrame', () async {
        var backend = getWriteFramesMock();

        var entries = <String, BoxEntry>{};
        var box = getBox(backend: backend, entries: entries);

        await box.putAll({'key1': null});
        verifyZeroInteractions(backend);

        await box.putAll({'key1': 'val1', 'key2': 'val2', 'key3': null});
        expect(entries.keys, ['key1', 'key2']);
        verify(backend.writeFrames([
          const Frame('key1', 'val1'),
          const Frame('key2', 'val2'),
        ], false));

        await box.putAll({'key1': null});
        expect(entries.keys, ['key2']);
        verify(backend.writeFrames([const Frame('key1', null)], false));
      });

      test('compaction', () async {
        var backend = getWriteFramesMock();
        var entries = 0;
        var deletedEntries = 0;
        var shouldCompact = false;
        var box = getBox(
          backend: backend,
          cStrategy: (e, d) {
            entries = e;
            deletedEntries = d;
            return shouldCompact;
          },
        );

        await box.putAll({'key1': null});
        expect(entries, 0);
        expect(deletedEntries, 0);

        await box
            .putAll({'key1': 'value1', 'key1': 'value2', 'key1': 'value3'});
        expect(entries, 1);
        expect(deletedEntries, 0);

        await box.putAll({'key1': 'value4'});
        expect(entries, 1);
        expect(deletedEntries, 1);

        await box.putAll({'key1': null});
        expect(entries, 0);
        expect(deletedEntries, 2);

        verifyNever(backend.compact(any));
        shouldCompact = true;

        await box.putAll({'key1': 'abc'});
        expect(entries, 1);
        expect(deletedEntries, 2);
        verify(backend.compact({'key1': const BoxEntry(null, null, null)}));
      });
    });

    test('delete()', () {});

    test('deleteAll()', () {});

    group('.toMap()', () {
      test('not lazy', () async {
        var entries = {
          'key1': const BoxEntry(1, 0, 0),
          'key2': const BoxEntry(2, 0, 0),
          'key4': const BoxEntry(444, 0, 0)
        };
        var box = getBox(entries: entries);
        expect(await box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
      });

      test('lazy', () async {
        var backend = BackendMock();
        when(backend.readAll(any))
            .thenAnswer((i) async => {'key1': 1, 'key2': 2, 'key4': 444});
        var entries = {
          'key1': const BoxEntry(null, 0, 0),
          'key2': const BoxEntry(null, 0, 0),
          'key4': const BoxEntry(null, 0, 0)
        };
        var box = getBox(entries: entries, lazy: true, backend: backend);
        expect(await box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
        verify(backend.readAll(['key1', 'key2', 'key4']));
      });
    });

    group('.clear()', () {
      test('does nothing if there are no entries', () async {
        var backend = BackendMock();
        var notifier = ChangeNotifierMock();
        var box = getBox(backend: backend, notifier: notifier, entries: {});

        expect(await box.clear(), 0);
        verifyZeroInteractions(backend);
        verifyZeroInteractions(notifier);
      });

      test('multiple entries', () async {
        var backend = BackendMock();
        var notifier = ChangeNotifierMock();
        var box = getBox(backend: backend, notifier: notifier, entries: {
          'key1': const BoxEntry(null, null, null),
          'key2': const BoxEntry(null, null, null)
        });
        await box.delete('key1');

        expect(await box.clear(), 1);
        expect(box.debugDeletedEntries, 0);
        verify(backend.clear());
        verify(notifier.notify('key1', null));
      });
    });

    group('.compact()', () {
      test('does nothing if there are no deleted entries', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend, entries: {
          'key1': const BoxEntry(null, null, null),
        });
        await box.compact();
        verifyZeroInteractions(backend);
      });

      test('ignores null returned by Backend.compact()', () async {
        var backend = BackendMock();
        var entries = {'key1': const BoxEntry(null, null, null)};
        var box = getBox(backend: backend, entries: entries);
        await box.compact();
        expect(box.debugEntries, entries);
      });
    });

    test('.close()', () {});

    test('.deleteFromDisk()', () {});
  });

  group('BoxEvent', () {
    test('.deleted', () {
      expect(BoxEvent('someKey', null).deleted, true);
      expect(BoxEvent('someKey', 'someVal').deleted, false);
    });
  });
}
