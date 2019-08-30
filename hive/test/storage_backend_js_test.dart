@TestOn('browser')

import 'dart:async' show Future;
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_js.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:test/test.dart';

import 'frames.dart';

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
        expect(backend.encodeValue([true, false]), [true, false]);

        var bytes = Uint8List.fromList([1, 2, 3]);
        var buffer = backend.encodeValue(bytes) as ByteBuffer;
        expect(Uint8List.view(buffer), [1, 2, 3]);
      });

      test('crypto', () {
        var backend = StorageBackendJs(null, testCrypto, testRegistry);
        var i = 0;
        for (var frame in testFrames) {
          var buffer = backend.encodeValue(frame.value) as ByteBuffer;
          var bytes = Uint8List.view(buffer);
          expect(bytes, [0x90, 0xA9, ...frameValuesBytesEncrypted[i]]);
          i++;
        }
      });

      group('non primitive', () {
        test('map', () {
          var map = {
            'key': Uint8List.fromList([1, 2, 3]),
            'otherKey': null
          };
          var backend = StorageBackendJs(null, null);
          var encoded = Uint8List.view(backend.encodeValue(map) as ByteBuffer);

          var writer = BinaryWriterImpl(null);
          Frame.encodeValue(map, writer, null);
          expect(encoded, [0x90, 0xA9, ...writer.output()]);
        });

        test('bytes which start with signature', () {
          var bytes = Uint8List.fromList([0x90, 0xA9, 1, 2, 3]);
          var backend = StorageBackendJs(null, null);
          var encoded =
              Uint8List.view(backend.encodeValue(bytes) as ByteBuffer);

          var writer = BinaryWriterImpl(null);
          Frame.encodeValue(bytes, writer, null);
          expect(encoded, [0x90, 0xA9, ...writer.output()]);
        });
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

        var bytes = Uint8List.fromList([1, 2, 3]);
        expect(backend.decodeValue(bytes.buffer), [1, 2, 3]);
      });

      test('crypto', () {
        var crypto = CryptoHelper(Uint8List.fromList(List.filled(32, 1)));
        var backend = StorageBackendJs(null, crypto, testRegistry);
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = [0x90, 0xA9, ...frameValuesBytesEncrypted[i]];
          var value = backend.decodeValue(Uint8List.fromList(bytes).buffer);
          expect(value, testFrame.value);
          i++;
        }
      });

      test('non primitive', () {
        var backend = StorageBackendJs(null, null, testRegistry);
        for (var testFrame in testFrames) {
          var bytes = backend.encodeValue(testFrame.value);
          var value = backend.decodeValue(bytes);
          expect(value, testFrame.value);
        }
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
        expect(await backend.initialize(null, entries, false, false), 0);
        expect(entries,
            {'key1': BoxEntry(1), 'key2': BoxEntry(null), 'key3': BoxEntry(3)});
      });

      test('lazy', () async {
        var db = await getDbWith({'key1': 1, 'key2': null, 'key3': 3});
        var backend = StorageBackendJs(db, null);

        var entries = <String, BoxEntry>{};
        expect(await backend.initialize(null, entries, true, false), 0);
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
