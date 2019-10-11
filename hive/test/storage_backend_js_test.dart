@TestOn('browser')

import 'dart:async' show Future;
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend_js.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:test/test.dart';

import 'frames.dart';

StorageBackendJs _getBackend({
  Database db,
  bool lazy = false,
  CryptoHelper crypto,
  TypeRegistry registry,
}) {
  return StorageBackendJs(db, lazy, crypto, registry);
}

Future<Database> _openDb() async {
  return await window.indexedDB.open('testBox', version: 1,
      onUpgradeNeeded: (e) {
    var db = e.target.result as Database;
    if (!db.objectStoreNames.contains('box')) {
      db.createObjectStore('box');
    }
  });
}

ObjectStore _getStore(Database db) {
  return db.transaction('box', 'readwrite').objectStore('box');
}

Future<Database> _getDbWith(Map<String, dynamic> content) async {
  var db = await _openDb();
  var store = _getStore(db);
  await store.clear();
  content.forEach((k, v) => store.put(v, k));
  return db;
}

void main() {
  group('StorageBackendJs', () {
    test('.path', () {
      expect(_getBackend().path, null);
    });

    group('.encodeValue()', () {
      test('primitive', () {
        var backend = _getBackend();
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
        var backend = StorageBackendJs(null, false, testCrypto, testRegistry);
        var i = 0;
        for (var frame in testFrames) {
          var buffer = backend.encodeValue(frame.value) as ByteBuffer;
          var bytes = Uint8List.view(buffer);
          expect(bytes.sublist(28),
              [0x90, 0xA9, ...frameValuesBytesEncrypted[i]].sublist(28));
          i++;
        }
      });

      group('non primitive', () {
        test('map', () {
          var map = {
            'key': Uint8List.fromList([1, 2, 3]),
            'otherKey': null
          };
          var backend = StorageBackendJs(null, false, null);
          var encoded = Uint8List.view(backend.encodeValue(map) as ByteBuffer);

          var writer = BinaryWriterImpl(null);
          Frame.encodeValue(map, writer, null);
          expect(encoded, [0x90, 0xA9, ...writer.toBytes()]);
        });

        test('bytes which start with signature', () {
          var bytes = Uint8List.fromList([0x90, 0xA9, 1, 2, 3]);
          var backend = _getBackend();
          var encoded =
              Uint8List.view(backend.encodeValue(bytes) as ByteBuffer);

          var writer = BinaryWriterImpl(null);
          Frame.encodeValue(bytes, writer, null);
          expect(encoded, [0x90, 0xA9, ...writer.toBytes()]);
        });
      });
    });

    group('.decodeValue()', () {
      test('primitive', () {
        var backend = _getBackend();
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
        var backend = _getBackend(crypto: crypto, registry: testRegistry);
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = [0x90, 0xA9, ...frameValuesBytesEncrypted[i]];
          var value = backend.decodeValue(Uint8List.fromList(bytes).buffer);
          expect(value, testFrame.value);
          i++;
        }
      });

      test('non primitive', () {
        var backend = _getBackend(registry: testRegistry);
        for (var testFrame in testFrames) {
          var bytes = backend.encodeValue(testFrame.value);
          var value = backend.decodeValue(bytes);
          expect(value, testFrame.value);
        }
      });
    });

    test('.getKeys()', () async {
      var db = await _getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = _getBackend(db: db);

      expect(await backend.getKeys(), ['key1', 'key2', 'key3']);
    });

    test('.getValues()', () async {
      var db = await _getDbWith({'key1': 1, 'key2': null, 'key3': 3});
      var backend = _getBackend(db: db);

      expect(await backend.getValues(), [1, null, 3]);
    });

    group('.initialize()', () {
      test('not lazy', () async {
        var db = await _getDbWith({'key1': 1, 'key2': null, 'key3': 3});
        var backend = _getBackend(db: db);

        var keystore = Keystore(null, ChangeNotifier());
        expect(await backend.initialize(null, keystore), 0);
        expect(keystore.frames, [
          Frame('key1', 1),
          Frame('key2', null),
          Frame('key3', 3),
        ]);
      });

      test('lazy', () async {
        var db = await _getDbWith({'key1': 1, 'key2': null, 'key3': 3});
        var backend = _getBackend(db: db, lazy: true);

        var keystore = Keystore(null, ChangeNotifier());
        expect(await backend.initialize(null, keystore), 0);
        expect(keystore.frames, [
          Frame.lazy('key1'),
          Frame.lazy('key2'),
          Frame.lazy('key3'),
        ]);
      });
    });

    test('.readValue()', () async {
      var db = await _getDbWith({'key1': 1, 'key2': null, 'key3': 3});
      var backend = _getBackend(db: db);

      expect(await backend.readValue(Frame('key1', null)), 1);
      expect(await backend.readValue(Frame('key2', null)), null);
    });

    test('.writeFrames()', () async {
      var db = await _getDbWith({});
      var backend = _getBackend(db: db);

      var frames = [Frame('key1', 123), Frame('key2', null)];
      await backend.writeFrames(frames);
      expect(frames, [Frame('key1', 123), Frame('key2', null)]);
      expect(await backend.getKeys(), ['key1', 'key2']);

      await backend.writeFrames([Frame.deleted('key1')]);
      expect(await backend.getKeys(), ['key2']);
    });

    test('.compact()', () async {
      var db = await _getDbWith({});
      var backend = _getBackend(db: db);
      expect(
        () async => await backend.compact({}),
        throwsUnsupportedError,
      );
    });

    test('.clear()', () async {
      var db = await _getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = _getBackend(db: db);
      await backend.clear();
      expect(await backend.getKeys(), []);
    });

    test('.close()', () async {
      var db = await _getDbWith({'key1': 1, 'key2': 2, 'key3': 3});
      var backend = _getBackend(db: db);
      await backend.close();

      expect(() async => await backend.getKeys(), throwsA(anything));
    });
  });
}
