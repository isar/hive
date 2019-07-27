import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_transaction_mixin.dart';
import 'package:meta/meta.dart';

class TransactionBox with BoxTransactionMixin implements Box {
  final Box _box;
  final Map<String, dynamic> _newEntries;

  TransactionBox(this._box) : _newEntries = HashMap<String, dynamic>();

  @visibleForTesting
  TransactionBox.debug(this._box, this._newEntries);

  @override
  String get name => _box.name;

  @override
  bool get isOpen => _box.isOpen;

  @override
  String get path => _box.path;

  @override
  Iterable<String> get keys {
    var keys = _box.keys.toSet()
      ..addAll(_newEntries.keys)
      ..removeWhere(
          (key) => _newEntries.containsKey(key) && _newEntries[key] == null);
    return keys;
  }

  @override
  Stream<BoxEvent> watch({String key}) {
    throw UnsupportedError('Watching a transaction is not supported.');
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
    if (_newEntries.containsKey(key)) {
      return _newEntries[key];
    } else {
      return _box[key];
    }
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
    for (var key in keys) {
      _newEntries[key] = null;
    }
    return Future.value();
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    var map = await _box.toMap();
    map
      ..addAll(_newEntries)
      ..removeWhere((key, val) => val == null);
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
  Future<void> close() {
    throw UnsupportedError('Cannot close box within transaction.');
  }

  @override
  Future<void> deleteFromDisk() {
    throw UnsupportedError('Cannot delete box within transaction.');
  }

  @override
  ResolvedAdapter findAdapterForType(Type type) {
    return _box.findAdapterForType(type);
  }

  @override
  ResolvedAdapter findAdapterForTypeId(int typeId) {
    return _box.findAdapterForTypeId(typeId);
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, int typeId) {
    throw UnsupportedError('Cannot add new adapters within a transaction.');
  }
}
