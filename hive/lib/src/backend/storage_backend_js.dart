import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:meta/meta.dart';

Future<StorageBackend> openBackend(
    String path, String name, CryptoHelper crypto) async {
  var db = await window.indexedDB.open(name, version: 1, onUpgradeNeeded: (e) {
    var db = e.target.result as Database;
    if (!db.objectStoreNames.contains('box')) {
      db.createObjectStore('box');
    }
  });

  return StorageBackendJs(db, crypto);
}

class StorageBackendJs extends StorageBackend {
  final Database _db;
  final CryptoHelper _crypto;

  TypeRegistry _registry;

  StorageBackendJs(this._db, this._crypto, [this._registry]);

  @override
  String get path => null;

  @override
  bool supportsCompaction = false;

  bool _isEncoded(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0x90 && bytes[1] == 0xA9;
  }

  @visibleForTesting
  dynamic encodeValue(dynamic value) {
    if (_crypto == null) {
      if (value == null) {
        return value;
      } else if (value is Uint8List) {
        if (!_isEncoded(value)) {
          return value.buffer;
        }
      } else if (value is num ||
          value is bool ||
          value is String ||
          value is List<num> ||
          value is List<bool> ||
          value is List<String>) {
        return value;
      }
    }

    var frameWriter = BinaryWriterImpl(_registry);
    frameWriter.writeByteList([0x90, 0xA9], writeLength: false);
    Frame.encodeValue(value, frameWriter, _crypto);
    return frameWriter.output().buffer;
  }

  @visibleForTesting
  dynamic decodeValue(dynamic value) {
    if (value is ByteBuffer) {
      var bytes = Uint8List.view(value);
      if (_isEncoded(bytes)) {
        var frameReader = BinaryReaderImpl(bytes, _registry, bytes.length);
        frameReader.skip(2);
        return Frame.decodeValue(frameReader, _crypto);
      } else {
        return bytes;
      }
    } else {
      return value;
    }
  }

  ObjectStore getStore(bool write, [String box = 'box']) {
    return _db
        .transaction(box, write ? 'readwrite' : 'readonly')
        .objectStore(box);
  }

  Future<List<dynamic>> getKeys() {
    var completer = Completer<List<dynamic>>();
    var request = getStore(false).getAllKeys(null);
    request.onSuccess.listen((_) {
      completer.complete(request.result as List<dynamic>);
    });
    request.onError.listen((_) {
      completer.completeError(request.error);
    });
    return completer.future;
  }

  Future<List<dynamic>> getValues() {
    var completer = Completer<List<dynamic>>();
    var request = getStore(false).getAll(null);
    request.onSuccess.listen((_) {
      var values = (request.result as List).map(decodeValue).toList();
      completer.complete(values);
    });
    request.onError.listen((_) {
      completer.completeError(request.error);
    });
    return completer.future;
  }

  @override
  Future<int> initialize(TypeRegistry registry, Map<dynamic, BoxEntry> entries,
      bool lazy, bool crashRecovery) async {
    _registry = registry;
    var keys = await getKeys();
    if (!lazy) {
      var values = await getValues();
      for (var i = 0; i < keys.length; i++) {
        entries[keys[i]] = BoxEntry(values[i], null, null);
      }
    } else {
      for (var i = 0; i < keys.length; i++) {
        entries[keys[i]] = BoxEntry(null);
      }
    }

    return 0;
  }

  @override
  Future<dynamic> readValue(dynamic key, int offset, int length) async {
    var value = await getStore(false).getObject(key);
    return decodeValue(value);
  }

  @override
  Future<Map<dynamic, dynamic>> readAll() async {
    var keys = await getKeys();
    var values = await getValues();
    return Map<dynamic, dynamic>.fromIterables(keys, values);
  }

  @override
  Future<void> writeFrame(Frame frame, BoxEntry entry) async {
    if (frame.deleted) {
      await getStore(true).delete(frame.key);
    } else {
      await getStore(true).put(encodeValue(frame.value), frame.key);
    }
  }

  @override
  Future<void> writeFrames(
      List<Frame> frames, Iterable<BoxEntry> entries) async {
    var store = getStore(true);
    for (var frame in frames) {
      if (frame.deleted) {
        await store.delete(frame.key);
      } else {
        await store.put(encodeValue(frame.value), frame.key);
      }
    }
  }

  @override
  Future<Map<dynamic, BoxEntry>> compact(Map<dynamic, BoxEntry> entries) {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> clear() {
    return getStore(true).clear();
  }

  @override
  Future<void> close() {
    _db.close();
    return Future.value();
  }

  @override
  Future<void> deleteFromDisk() {
    return window.indexedDB.deleteDatabase(_db.name);
  }
}
