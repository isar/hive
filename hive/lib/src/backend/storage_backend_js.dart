import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

Future<Box> openBoxInternal(
    HiveImpl hive, String name, bool lazy, BoxOptions options) async {
  var db = await window.indexedDB.open(name, version: 1, onUpgradeNeeded: (e) {
    var db = e.target.result as Database;
    if (!db.objectStoreNames.contains('box')) {
      db.createObjectStore('box');
    }
  });

  CryptoHelper crypto;
  if (options.encrypted) {
    crypto = CryptoHelper(Uint8List.fromList(options.encryptionKey));
  }

  var backend = StorageBackendJs(db, crypto);
  BoxBase box;
  if (lazy) {
    box = LazyBoxImpl(hive, name, options, backend);
  } else {
    box = BoxImpl(hive, name, options, backend);
  }
  backend._registry = box;

  await box.initialize();

  return box;
}

class StorageBackendJs extends StorageBackend {
  final Database _db;
  final CryptoHelper _crypto;

  TypeRegistry _registry;

  StorageBackendJs(this._db, this._crypto);

  @override
  String get path => null;

  @visibleForTesting
  dynamic encodeValue(dynamic value) {
    var noEncodingNeeded = value is num ||
        value is bool ||
        value is String ||
        (value is List<num> && value is! Uint8List) ||
        value is List<bool> ||
        value is List<String>;

    if (noEncodingNeeded && _crypto == null) {
      return value;
    } else {
      var bytes = Frame('', value).toBytes(false, _registry, _crypto);
      return bytes.buffer;
    }
  }

  @visibleForTesting
  dynamic decodeValue(dynamic value) {
    if (value is ByteBuffer) {
      var bytes = Uint8List.view(value);
      return Frame.bodyFromBytes(bytes, _registry, _crypto).value;
    } else {
      return value;
    }
  }

  ObjectStore getStore(bool write, [String box = 'box']) {
    return _db
        .transaction(box, write ? 'readwrite' : 'readonly')
        .objectStore(box);
  }

  Future<List<String>> getKeys() {
    var completer = Completer<List<String>>();
    var request = getStore(false).getAllKeys(null);
    request.onSuccess.listen((_) {
      var keys = request.result.cast<String>() as List<String>;
      completer.complete(keys);
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
  Future<int> initialize(
      Map<dynamic, BoxEntry> entries, bool lazy, bool crashRecovery) async {
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
    return Future.value(entries);
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
