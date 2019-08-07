import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/box/transaction_base.dart';
import 'package:meta/meta.dart';

abstract class BoxTransactionMixin<T extends Box> implements Box {
  final _runningTransactions = <Future<void>>[];

  int autoIncrement();

  @override
  Future<int> add(dynamic value) async {
    var key = autoIncrement();
    await put(key, value);
    return key;
  }

  @override
  Future<List<int>> addAll(List<dynamic> values) async {
    var entries = <int, dynamic>{};
    for (var value in values) {
      entries[autoIncrement()] = value;
    }
    await putAll(entries);
    return entries.keys.toList();
  }

  TransactionBase<T> getTransaction();

  Future<void> transaction(Future Function(T box) transaction) async {
    var completer = Completer<void>();
    var completerFuture = completer.future;
    _runningTransactions.add(completerFuture);
    var trxBox = getTransaction();
    await transaction(trxBox as T);
    await trxBox.commit();
    completer.complete();
    _runningTransactions.remove(completerFuture);
  }

  @protected
  @visibleForTesting
  Future<void> waitForRunningTransactions() {
    return Future.wait(_runningTransactions);
  }
}
