@TestOn('browser')

import 'dart:async' show Future;
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_js.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/crypto.dart';
import 'package:test/test.dart';

Future<Database> openDb() async {
  return await window.indexedDB.open('testBox', version: 1,
      onUpgradeNeeded: (e) {
    Database db = e.target.result;
    if (!db.objectStoreNames.contains('box')) {
      db.createObjectStore('box');
    }
  });
}

ObjectStore getStore(Database db) {
  return db.transaction('box', 'readwrite').objectStore('box');
}

Future<Database> getDbWith(Map<String, dynamic> content) async {
  var db = await openDb();
  var store = getStore(db);
  await store.clear();
  content.forEach((k, v) => store.put(v, k));
  return db;
}

void main() {
  group('StorageBackendJs', () {
    test('.path', () {
      expect(StorageBackendJs(null, null).path, null);
    });

    group('.encodeValue()', () {
      test('primitive', () {
        var backend = StorageBackendJs(null, null);
        expect(backend.encodeValue(11), 11);
        expect(backend.encodeValue(17.25), 17.25);
        expect(backend.encodeValue(true), true);
        expect(backend.encodeValue('hello'), 'hello');
        expect(backend.encodeValue([11, 12, 13]), [11, 12, 13]);
        expect(backend.encodeValue([17.25, 17.26]), [17.25, 17.26]);
      });

      test('primitive crypto', () {
        var crypto = Crypto(Uint8List.fromList(List.filled(32, 1)));
        var backend = StorageBackendJs(null, crypto);
        var bytes = Uint8List.view(backend.encodeValue(1));
        var frame = Frame.fromBytes(null, bytes, false, null, crypto);
        expect(frame.value, 1);
      });

      test('non primitive', () {
        var backend = StorageBackendJs(null, null);
        var map = {
          'key': Uint8List.fromList([1, 2, 3]),
          'otherKey': null
        };
        var bytes = Uint8List.view(backend.encodeValue(map));
        var frame = Frame.fromBytes(null, bytes, false, null, null);
        expect(frame.value, map);
      });
    });

    group('.decodeValue()', () {
      test('primitive', () {
        var backend = StorageBackendJs(null, null);
        expect(backend.decodeValue(11), 11);
        expect(backend.decodeValue(17.25), 17.25);
        expect(backend.decodeValue(true), true);
        expect(backend.decodeValue('hello'), 'hello');
        expect(backend.decodeValue([11, 12, 13]), [11, 12, 13]);
        expect(backend.decodeValue([17.25, 17.26]), [17.25, 17.26]);
      });

      test('primitive crypto', () {
        var crypto = Crypto(Uint8List.fromList(List.filled(32, 1)));
        var backend = StorageBackendJs(null, crypto);
        var bytes = Frame('', 1).toBytes(null, false, crypto);
        var value = backend.decodeValue(bytes.buffer);
        expect(value, 1);
      });
    });

    test('.getKeys()', () async {
      var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.getKeys(), ['key1', 'key2', 'key3']);
    });

    test('.getValues()', () async {
      var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.getValues(), [1, 2, 3]);
    });

    group('.initialize()', () {
      test('cached', () async {
        var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
        var backend = StorageBackendJs(db, null);

        var entries = Map<String, BoxEntry>();
        expect(await backend.initialize(entries, true), 0);
        expect(entries, {
          'key1': BoxEntry(1, null, null),
          'key2': BoxEntry(2, null, null),
          'key3': BoxEntry(3, null, null)
        });
      });

      test('not cached', () async {
        var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
        var backend = StorageBackendJs(db, null);

        var entries = Map<String, BoxEntry>();
        expect(await backend.initialize(entries, false), 0);
        expect(entries, {
          'key1': BoxEntry(null, null, null),
          'key2': BoxEntry(null, null, null),
          'key3': BoxEntry(null, null, null)
        });
      });
    });

    test('.readValue()', () async {
      var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.readValue('key2', null, null), 2);
    });

    test('.readAll()', () async {
      var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.readAll(['key1', 'key2', 'key3']),
          {'key1': 1, 'key2': 2, 'key3': 3});
    });

    test('.writeFrame()', () async {
      var db = await getDbWith({});
      var backend = StorageBackendJs(db, null);

      var entry = await backend.writeFrame(Frame('key1', 123), true);
      expect(entry, BoxEntry(123, null, null));
      expect(await backend.getKeys(), ['key1']);

      entry = await backend.writeFrame(Frame('key2', 456), false);
      expect(entry, BoxEntry(null, null, null));
      expect(await backend.getKeys(), ['key1', 'key2']);

      entry = await backend.writeFrame(Frame('key1', null), true);
      expect(entry, null);
      expect(await backend.getKeys(), ['key2']);
    });

    test('.writeFrames()', () async {
      var db = await getDbWith({});
      var backend = StorageBackendJs(db, null);

      var entries = await backend
          .writeFrames([Frame('key1', 123), Frame('key2', 456)], true);
      expect(entries, [BoxEntry(123, null, null), BoxEntry(456, null, null)]);
      expect(await backend.getKeys(), ['key1', 'key2']);

      entries = await backend
          .writeFrames([Frame('key1', null), Frame('key3', 789)], false);
      expect(entries, [null, BoxEntry(null, null, null)]);
      expect(await backend.getKeys(), ['key2', 'key3']);
    });

    test('.compact()', () async {
      var db = await getDbWith({});
      var backend = StorageBackendJs(db, null);

      var entries = {
        'key1': BoxEntry(null, null, null),
        'key2': BoxEntry(null, null, null)
      };
      expect(await backend.compact(entries), entries);
    });

    test('.clear()', () async {
      var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = StorageBackendJs(db, null);
      await backend.clear();
      expect(await backend.getKeys(), []);
    });

    test('.close()', () async {
      var db = await getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = StorageBackendJs(db, null);
      await backend.close();

      expect(() async => await backend.getKeys(), throwsA(anything));
    });
  });
}