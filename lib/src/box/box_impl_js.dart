import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/frame.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

Future<BoxImpl> openBox(HiveImpl hive, String name, BoxOptions options) async {
  var db = await window.indexedDB.open(name, version: 1, onUpgradeNeeded: (e) {
    Database db = e.target.result;
    if (!db.objectStoreNames.contains("box")) {
      db.createObjectStore("box");
    }
  });
  var box = BoxImplJs(hive, name, options, db);
  await box.initialize();
  return box;
}

class BoxImplJs extends BoxImpl {
  final Database _db;

  Map<String, dynamic> _entries;

  BoxImplJs(HiveImpl hive, String name, BoxOptions options, this._db)
      : _entries = HashMap(),
        super(hive, name, options);

  @visibleForTesting
  dynamic encodeValue(dynamic value) {
    var noEncodingNeeded = !options.encrypted &&
        (value is num ||
            value is bool ||
            value is String ||
            value is List<num> ||
            value is List<bool> ||
            value is List<String>);

    if (noEncodingNeeded) {
      return value;
    } else {
      var writer = BinaryWriterImpl(this);
      Frame(null, value).encodeBody(writer, false, encryptor);
      return writer.output().buffer;
    }
  }

  @visibleForTesting
  dynamic decodeValue(dynamic value) {
    if (value is ByteBuffer) {
      var reader = BinaryReaderImpl(Uint8List.view(value), this);
      return Frame.decodeBody(reader, false, true, decryptor).value;
    } else {
      return value;
    }
  }

  ObjectStore getStore(bool write, [String box = "box"]) {
    return _db
        .transaction(box, write ? 'readwrite' : 'readonly')
        .objectStore(box);
  }

  Future<void> initialize() async {
    var keys = await getKeys();
    List values;
    if (options.inMemory) {
      values = await getValues();
    } else {
      values = List.filled(keys.length, null);
    }

    _entries = Map.fromIterables(keys, values);
  }

  Future<List<String>> getKeys() {
    var completer = Completer<List<String>>();
    var request = getStore(false).getAllKeys(null);
    request.onSuccess.listen((_) {
      var keys = request.result.cast<String>();
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
      List values = request.result.map(decodeValue).toList();
      completer.complete(values);
    });
    request.onError.listen((_) {
      completer.completeError(request.error);
    });
    return completer.future;
  }

  @override
  Iterable<String> allKeys() {
    return _entries.keys;
  }

  @override
  Future<int> clear() async {
    await getStore(true).clear();
    var numEntries = _entries.length;
    _entries.clear();
    return numEntries;
  }

  @override
  Future<void> compact() {
    return Future.value();
  }

  @override
  Future<bool> delete(String key) async {
    if (!_entries.containsKey(key)) return false;
    await getStore(true).delete(key);
    _entries.remove(key);
    return true;
  }

  @override
  Future<List<bool>> deleteAll(Iterable<String> keys) async {
    var result = List<bool>(keys.length);
    var store = getStore(true);
    for (var key in keys) {
      if (_entries.containsKey(key)) {
        await store.delete(key);
        _entries.remove(key);
        result.add(true);
      } else {
        result.add(false);
      }
    }

    return result;
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) async {
    if (!_entries.containsKey(key)) return defaultValue;
    if (options.inMemory) return _entries[key];

    var value = await getStore(false).getObject(key);
    return decodeValue(value);
  }

  @override
  bool has(String key) {
    return _entries.containsKey(key);
  }

  @override
  String get path => null;

  @override
  Future<void> put(String key, value) async {
    checkOpen();
    checkKey(key);
    await getStore(true).put(encodeValue(value), key);
    _entries[key] = options.inMemory ? value : null;
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) {
    // TODO: implement putAll
    return null;
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    if (options.inMemory) {
      return Map.unmodifiable(_entries);
    } else {
      return Map.fromIterables(_entries.keys, await getValues());
    }
  }
}
