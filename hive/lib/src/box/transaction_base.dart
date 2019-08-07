import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_transaction_mixin.dart';
import 'package:meta/meta.dart';

abstract class TransactionBase<T extends Box>
    with BoxTransactionMixin<T>
    implements Box {
  @protected
  final T box;

  @protected
  final Map<dynamic, dynamic> newEntries;

  final Set<dynamic> deletedKeys;

  final int Function() _autoIncrement;

  TransactionBase(this.box, this._autoIncrement)
      : newEntries = HashMap(),
        deletedKeys = <dynamic>{};

  @visibleForTesting
  TransactionBase.debug(
      this.box, this._autoIncrement, this.newEntries, this.deletedKeys);

  @override
  String get name => box.name;

  @override
  bool get isOpen => box.isOpen;

  @override
  String get path => box.path;

  @override
  int autoIncrement() {
    return _autoIncrement();
  }

  @override
  Iterable<dynamic> get keys {
    var keys = box.keys.toSet()
      ..addAll(newEntries.keys)
      ..removeWhere(
          (key) => newEntries.containsKey(key) && newEntries[key] == null);
    return keys;
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    throw UnsupportedError('Watching a transaction is not supported.');
  }

  @override
  bool containsKey(dynamic key) {
    if (deletedKeys.contains(key)) {
      return false;
    } else if (newEntries.containsKey(key)) {
      return true;
    } else {
      return box.containsKey(key);
    }
  }

  @override
  Future<void> put(dynamic key, value) {
    newEntries[key] = value;
    deletedKeys.remove(key);
    return Future.value();
  }

  @override
  Future<bool> delete(dynamic key) {
    deletedKeys.add(key);
    newEntries.remove(key);
    return Future.value();
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> entries) {
    newEntries.addAll(entries);
    deletedKeys.removeAll(entries.keys);
    return Future.value();
  }

  @override
  Future<List<bool>> deleteAll(Iterable<dynamic> keys) {
    for (var key in keys) {
      deletedKeys.add(key);
      newEntries.remove(key);
    }
    return Future.value();
  }

  Future commit() async {
    await waitForRunningTransactions();
    await box.putAll(newEntries);
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
    return box.findAdapterForType(type);
  }

  @override
  ResolvedAdapter findAdapterForTypeId(int typeId) {
    return box.findAdapterForTypeId(typeId);
  }

  @override
  void registerAdapter<A>(TypeAdapter<A> adapter, int typeId) {
    throw UnsupportedError('Cannot add new adapters within a transaction.');
  }
}
