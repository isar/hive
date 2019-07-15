import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

BoxImpl getBox(
    {String name,
    bool cached,
    StorageBackend backend,
    Map<String, BoxEntry> entries}) {
  return BoxImpl.debug(
      HiveImpl(),
      name ?? 'testBox',
      BoxOptions(cached: cached ?? true),
      backend ?? BackendMock(),
      entries ?? Map());
}

void main() {
  group('BoxImpl', () {
    test('.watch()', () async {
      var box = getBox(entries: {
        'key1': BoxEntry(123, 0, 0),
        'key2': BoxEntry(123, 0, 0),
      });

      var allEvents = List<BoxEvent>();
      box.watch().listen((e) {
        allEvents.add(e);
      });

      var filteredEvents = List<BoxEvent>();
      box.watch(key: 'key1').listen((e) {
        filteredEvents.add(e);
      });

      await box.delete('key1');
      await box.delete('someOtherKey');
      await box.put('key1', 'newVal');
      await box.put('key2', 'newVal2');

      await Future.delayed(Duration(milliseconds: 1));

      expect(allEvents, [
        BoxEvent('key1', null),
        BoxEvent('key1', 'newVal'),
        BoxEvent('key2', 'newVal2'),
      ]);

      expect(filteredEvents, [
        BoxEvent('key1', null),
        BoxEvent('key1', 'newVal'),
      ]);
    });

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
        var box = getBox(backend: backend, entries: {
          'testKey': BoxEntry('testVal', null, null),
        });

        reset(backend);
        expect(await box.get('testKey'), 'testVal');
        verifyZeroInteractions(backend);
      });

      test('reads value from backend', () async {
        var backend = BackendMock();
        when(backend.readValue(any, any)).thenAnswer((i) async => 'testVal');
        var box = getBox(
          cached: false,
          backend: backend,
          entries: {'testKey': BoxEntry('testVal', 123, null)},
        );

        expect(await box.get('testKey'), 'testVal');
        verify(backend.readValue('testKey', 123));
      });
    });

    group('[]', () {
      test('returns cached value', () {
        var box = getBox(entries: {'key': BoxEntry('value', 0, 0)});
        expect(box['key'], 'value');
        expect(box['nonexistantKey'], null);
      });

      test('throws if box not cached', () {
        var box = getBox(cached: false, entries: {});
        expect(() => box['key'], throwsHiveError('only cached boxes'));
      });
    });

    test('.has()', () {
      var backend = BackendMock();
      var box = getBox(
        backend: backend,
        entries: {'existingKey': BoxEntry(null, null, null)},
      );

      expect(box.has('existingKey'), true);
      expect(box.has('nonExistingKey'), false);
      verifyZeroInteractions(backend);
    });

    test('.put()', () async {
      var backend = BackendMock();
      when(backend.writeFrame(any, true))
          .thenAnswer((i) async => BoxEntry(null, null, null));
      var entries = Map<String, BoxEntry>();
      var box = getBox(backend: backend, entries: entries);

      await box.put('key1', null);
      expect(box.debugDeletedEntries, 0);
      verifyZeroInteractions(backend);

      await box.put('key1', 'value1');
      expect(entries.containsKey('key1'), true);
      expect(box.debugDeletedEntries, 0);
      verify(backend.writeFrame(Frame('key1', 'value1'), true));

      await box.put('key1', 'value2');
      expect(box.debugDeletedEntries, 1);

      await box.put('key1', null);
      expect(entries.containsKey('key1'), false);
      expect(box.debugDeletedEntries, 2);
    });

    test('[]=', () {
      var backend = BackendMock();
      var box = getBox(backend: backend, entries: {});
      box['key'] = 123;
      verify(backend.writeFrame(Frame('key', 123), true));
    });

    test('.putAll()', () async {
      var backend = BackendMock();
      var offset = 0;
      when(backend.writeFrames(any, true)).thenAnswer((i) async {
        return List.generate(i.positionalArguments[0].length,
            (i) => BoxEntry(null, offset++, 0));
      });
      var entries = Map<String, BoxEntry>();
      var box = getBox(backend: backend, entries: entries);

      await box.putAll({'key1': 'val1', 'key2': 'val2', 'key3': null});
      expect(entries, {
        'key1': BoxEntry(null, 0, 0),
        'key2': BoxEntry(null, 1, 0),
      });
      expect(box.debugDeletedEntries, 0);
      verify(backend.writeFrames([
        Frame('key1', 'val1'),
        Frame('key2', 'val2'),
      ], true));

      await box.putAll({'key1': 'val3', 'key2': null});
      expect(entries, {
        'key1': BoxEntry(null, 2, 0),
      });
      expect(box.debugDeletedEntries, 2);
    });

    test('.allKeys()', () async {
      var entries = {
        'key1': BoxEntry(null, 0, 0),
        'key2': BoxEntry(null, 0, 0),
        'key4': BoxEntry(null, 0, 0)
      };
      var box = getBox(entries: entries);
      expect(await box.allKeys(), ['key1', 'key2', 'key4']);
    });

    group('.toMap()', () {
      test('cached', () async {
        var entries = {
          'key1': BoxEntry(1, 0, 0),
          'key2': BoxEntry(2, 0, 0),
          'key4': BoxEntry(444, 0, 0)
        };
        var box = getBox(entries: entries);
        expect(await box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
      });

      test('not cached', () async {
        var backend = BackendMock();
        when(backend.readAll(any))
            .thenAnswer((i) async => {'key1': 1, 'key2': 2, 'key4': 444});
        var entries = {
          'key1': BoxEntry(null, 0, 0),
          'key2': BoxEntry(null, 0, 0),
          'key4': BoxEntry(null, 0, 0)
        };
        var box = getBox(entries: entries, cached: false, backend: backend);
        expect(await box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
        verify(backend.readAll(['key1', 'key2', 'key4']));
      });
    });

    group('.clear()', () {
      test('does nothing if there are no entries', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend, entries: {});

        expect(await box.clear(), 0);
        verifyZeroInteractions(backend);
      });

      test('multiple entries', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend, entries: {
          'key1': BoxEntry(null, null, null),
          'key2': BoxEntry(null, null, null)
        });
        await box.delete('key1');

        expect(await box.clear(), 1);
        expect(box.debugDeletedEntries, 0);
        verify(backend.clear());
      });
    });

    group('.compact()', () {
      test('does nothing if there are no deleted entries', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend, entries: {
          'key1': BoxEntry(null, null, null),
        });
        await box.compact();
        verifyZeroInteractions(backend);
      });

      test('ignores null returned by Backend.compact()', () async {
        var backend = BackendMock();
        var entries = {'key1': BoxEntry(null, null, null)};
        var box = getBox(backend: backend, entries: entries);
        await box.compact();
        expect(box.debugEntries, entries);
      });
    });
  });
}
