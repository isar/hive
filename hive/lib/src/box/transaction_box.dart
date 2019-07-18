import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base.dart';

class TransactionBox extends BoxBase {
  final Box _box;
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
    throw UnsupportedError('Watching is not supported within a transaction.');
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) {
    if (_newEntries.containsKey(key)) {
      return Future.value(_newEntries[key] as T ?? defaultValue);
    } else {
      return _box.get(key, defaultValue: defaultValue);
    }
  }

  @override
  dynamic operator [](String key) {
    if (_newEntries.containsKey(key)) return _newEntries[key];
    return _box[key];
  }

  @override
  bool has(String key) {
    if (_newEntries.containsKey(key)) {
      return _newEntries[key] != null;
    } else {
      return _box.has(key);
    }
  }

  @override
  Future<void> put(String key, value) {
    _newEntries[key] = value;
    return Future.value();
  }

  @override
  operator []=(String key, dynamic value) {
    _newEntries[key] = value;
  }

  @override
  Future<bool> delete(String key) {
    _newEntries[key] = null;
    return Future.value();
  }

  @override
  Future<void> putAll(Map<String, dynamic> entries) {
    _newEntries.addAll(entries);
    return Future.value();
  }

  @override
  Future<List<bool>> deleteAll(Iterable<String> keys) {
    var nullList = List.filled(keys.length, null);
    _newEntries.addAll(Map<String, void>.fromIterables(keys, nullList));
    return Future.value();
  }

  @override
  Iterable<String> allKeys() {
    var keys = _box.allKeys().toSet();
    keys.addAll(_newEntries.keys);
    keys.removeWhere((key) => _newEntries[key] == null);
    return keys;
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    var map = await _box.toMap();
    map.addAll(_newEntries);
    map.removeWhere((key, val) => val == null);
    return map;
  }

  Future commit() async {
    await waitForRunningTransactions();
    await _box.putAll(_newEntries);
  }

  @override
  Future<void> compact() {
    throw UnsupportedError('Cannot compact box within transaction.');
  }

  @override
  Future<int> clear() {
    throw UnsupportedError('Cannot clear box within transaction.');
  }

  @override
  Future<void> close({bool compact = false}) {
    throw UnsupportedError('Cannot close box within transaction.');
  }

  @override
  Future<void> deleteFromDisk() {
    throw UnsupportedError('Cannot delete box within transaction.');
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, int typeId) {
    throw UnsupportedError('Cannot add new adapters within a transaction.');
  }
}
