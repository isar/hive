import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base.dart';

class TransactionBox extends BoxBase {
  final Box _box;
  Set<String> _deletedKeys = Set();
  Map<String, dynamic> _newEntries = HashMap();

  TransactionBox(this._box) : super(_box);

  @override
  String get name => _box.name;

  @override
  bool get isOpen => _box.isOpen;

  @override
  String get path => _box.path;

  @override
  Stream<BoxEvent> watch() {
    throw UnsupportedError("Watching is not supported within a transaction.");
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) {
    if (_deletedKeys.contains(key)) {
      return Future.value(defaultValue);
    } else if (_newEntries.containsKey(key)) {
      return Future.value(_newEntries[key]);
    } else {
      return _box.get(key, defaultValue: defaultValue);
    }
  }

  @override
  Future operator [](String key) {
    return get(key);
  }

  @override
  bool has(String key) {
    if (_deletedKeys.contains(key))
      return false;
    else if (_newEntries.containsKey(key)) return true;
    return _box.has(key);
  }

  @override
  Future<void> put(String key, value) {
    _deletedKeys.remove(key);
    _newEntries[key] = value;
    return Future.value();
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) {
    for (var key in entries.keys) {
      _deletedKeys.remove(key);
    }
    _newEntries.addAll(entries);
    return Future.value();
  }

  @override
  Future<bool> delete(String key) {
    if (has(key)) {
      _deletedKeys.add(key);
      _newEntries.remove(key);
      return Future.value(true);
    }
    return Future.value(false);
  }

  @override
  Future<List<bool>> deleteAll(Iterable<String> keys) {
    var result = List<bool>(keys.length);
    var i = 0;
    for (var key in keys) {
      if (has(key)) {
        _deletedKeys.add(key);
        _newEntries.remove(key);
        result[i++] = true;
      } else {
        result[i++] = false;
      }
    }
    return Future.value(result);
  }

  @override
  Iterable<String> allKeys() {
    var keys = _box.allKeys().toSet();
    keys.removeWhere((key) => _deletedKeys.contains(key));
    keys.addAll(_newEntries.keys);
    return keys;
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    var map = await _box.toMap();
    map.removeWhere((key, val) => _deletedKeys.contains(key));
    map.addAll(_newEntries);
    return map;
  }

  Future commit() async {
    await waitForRunningTransactions();
    await _box.deleteAll(_deletedKeys);
    await _box.putAll(_newEntries);
  }

  @override
  Future<void> compact() {
    throw UnsupportedError("Cannot compact box within transaction.");
  }

  @override
  Future<int> clear() {
    throw UnsupportedError("Cannot clear box within transaction.");
  }

  @override
  Future<void> close({bool compact = false}) {
    throw UnsupportedError("Cannot close box within transaction.");
  }

  @override
  Future<void> deleteFromDisk() {
    throw UnsupportedError("Cannot delete box within transaction.");
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, int typeId) {
    throw UnsupportedError("Cannot add new adapters within a transaction.");
  }
}
