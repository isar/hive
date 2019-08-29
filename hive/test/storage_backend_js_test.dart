@TestOn('browser')

import 'dart:async' show Future;
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_js.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:test/test.dart';

Future<Database> openDb() async {
  return await window.indexedDB.open('testBox', version: 1,
      onUpgradeNeeded: (e) {
    var db = e.target.result as Database;
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
        expect(backend.encodeValue(null), null);
        expect(backend.encodeValue(11), 11);
        expect(backend.encodeValue(17.25), 17.25);
        expect(backend.encodeValue(true), true);
        expect(backend.encodeValue('hello'), 'hello');
        expect(backend.encodeValue([11, 12, 13]), [11, 12, 13]);
        expect(backend.encodeValue([17.25, 17.26]), [17.25, 17.26]);
      });

      test('primitive crypto', () {
        var crypto = CryptoHelper(Uint8List.fromList(List.filled(32, 1)));
        var backend = StorageBackendJs(null, crypto);
        var bytes = Uint8List.view(backend.encodeValue(1) as ByteBuffer);
        var frame = Frame.bodyFromBytes(bytes, null, crypto);
        expect(frame.value, 1);
      });

      test('non primitive', () {
        var backend = StorageBackendJs(null, null);
        var map = {
          'key': Uint8List.fromList([1, 2, 3]),
          'otherKey': null
        };
        var bytes = Uint8List.view(backend.encodeValue(map) as ByteBuffer);
        var frame = Frame.bodyFromBytes(bytes, null, null);
        expect(frame.value, map);
      });
    });

    group('.decodeValue()', () {
      test('primitive', () {
        var backend = StorageBackendJs(null, null);
        expect(backend.decodeValue(null), null);
        expect(backend.decodeValue(11), 11);
        expect(backend.decodeValue(17.25), 17.25);
        expect(backend.decodeValue(true), true);
        expect(backend.decodeValue('hello'), 'hello');
        expect(backend.decodeValue([11, 12, 13]), [11, 12, 13]);
        expect(backend.decodeValue([17.25, 17.26]), [17.25, 17.26]);
      });

      test('primitive crypto', () {
        var crypto = CryptoHelper(Uint8List.fromList(List.filled(32, 1)));
        var backend = StorageBackendJs(null, crypto);
        var bytes = const Frame('', 1).toBytes(false, null, crypto);
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
      var db = await getDbWith({'key1': 1, 'key2': null, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.getValues(), [1, null, 3]);
    });

    group('.initialize()', () {
      test('not lazy', () async {
        var db = await getDbWith({'key1': 1, 'key2': null, 'key3': 3});
        var backend = StorageBackendJs(db, null);

        var entries = <String, BoxEntry>{};
        expect(await backend.initialize(entries, false, false), 0);
        expect(entries,
            {'key1': BoxEntry(1), 'key2': BoxEntry(null), 'key3': BoxEntry(3)});
      });

      test('lazy', () async {
        var db = await getDbWith({'key1': 1, 'key2': null, 'key3': 3});
        var backend = StorageBackendJs(db, null);

        var entries = <String, BoxEntry>{};
        expect(await backend.initialize(entries, true, false), 0);
        expect(entries, {
          'key1': BoxEntry(null),
          'key2': BoxEntry(null),
          'key3': BoxEntry(null)
        });
      });
    });

    test('.readValue()', () async {
      var db = await getDbWith({'key1': 1, 'key2': null, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.readValue('key1', null, null), 1);
      expect(await backend.readValue('key2', null, null), null);
    });

    test('.readAll()', () async {
      var db = await getDbWith({'key1': 1, 'key2': null, 'key3': 3});
      var backend = StorageBackendJs(db, null);

      expect(await backend.readAll(), {'key1': 1, 'key2': null, 'key3': 3});
    });

    test('.writeFrame()', () async {
      var db = await getDbWith({});
      var backend = StorageBackendJs(db, null);

      var entry = BoxEntry(null);
      await backend.writeFrame(const Frame('key1', 123), entry);
      expect(entry, BoxEntry(null));
      expect(await backend.getKeys(), ['key1']);

      await backend.writeFrame(const Frame('key2', null), entry);
      expect(await backend.getKeys(), ['key1', 'key2']);

      await backend.writeFrame(const Frame.deleted('key1'), entry);
      expect(await backend.getKeys(), ['key2']);
    });

    test('.writeFrames()', () async {
      var db = await getDbWith({});
      var backend = StorageBackendJs(db, null);

      var entries = [BoxEntry(null), BoxEntry(null)];
      await backend.writeFrames([
        const Frame('key1', 123),
        const Frame('key2', null),
      ], entries);
      expect(entries, [BoxEntry(null), BoxEntry(null)]);
      expect(await backend.getKeys(), ['key1', 'key2']);
    });

    test('.compact()', () async {
      var db = await getDbWith({});
      var backend = StorageBackendJs(db, null);
      expect(
        () async => await backend.compact({}),
        throwsUnsupportedError,
      );
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
