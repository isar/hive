import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/cached_box.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

CachedBox getBox({
  String name,
  HiveImpl hive,
  StorageBackend backend,
  ChangeNotifier notifier,
  Keystore keystore,
  CompactionStrategy cStrategy,
}) {
  return CachedBox.debug(
    hive ?? HiveImpl(),
    name ?? 'testBox',
    BoxOptions(
      lazy: false,
      compactionStrategy: cStrategy ?? (total, deleted) => false,
    ),
    backend ?? BackendMock(),
    keystore ?? Keystore(),
    notifier,
  );
}

void main() {
  group('CachedBox', () {
    group('.get()', () {
      test('returns defaultValue if key does not exist', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend);

        expect(await box.get('someKey'), null);
        expect(await box.get('otherKey', defaultValue: -12), -12);
        verifyZeroInteractions(backend);
      });

      test('returns cached value if it exists', () async {
        var backend = BackendMock();
        var box = getBox(
          backend: backend,
          keystore: Keystore({
            'testKey': BoxEntry('testVal', null, null),
          }),
        );

        reset(backend);
        expect(await box.get('testKey'), 'testVal');
        verifyZeroInteractions(backend);
      });
    });

    test('[]', () {
      var box = getBox(
        keystore: Keystore({'key': BoxEntry('value', 0, 0)}),
      );
      expect(box['key'], 'value');
      expect(box['nonexistantKey'], null);
    });
  });

  group('.put()', () {
    BackendMock getWriteFrameMock() {
      var backend = BackendMock();
      when(backend.writeFrame(any, any))
          .thenAnswer((i) async => const BoxEntry(null));
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
      verify(backend.compact({'key1': const BoxEntry(null)}));
    });
  });

  group('.putAll()', () {
    BackendMock getWriteFramesMock() {
      var backend = BackendMock();
      when(backend.writeFrames(any, false)).thenAnswer((i) async {
        return List.filled(
            (i.positionalArguments[0] as List).length, const BoxEntry(null));
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

      await box.putAll({'key1': 'value1', 'key1': 'value2', 'key1': 'value3'});
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
      verify(backend.compact({'key1': const BoxEntry(null)}));
    });
  });

  group('.toMap()', () async {
    var box = getBox(
      keystore: Keystore({
        'key1': BoxEntry(1, 0, 0),
        'key2': BoxEntry(2, 0, 0),
        'key4': BoxEntry(444, 0, 0),
      }),
    );
    expect(await box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
  });
}
