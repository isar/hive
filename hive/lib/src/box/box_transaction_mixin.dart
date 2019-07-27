import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/box/transaction_box.dart';
import 'package:meta/meta.dart';

abstract class BoxTransactionMixin implements Box {
  final _runningTransactions = <Future<void>>[];

  @override
  Future<void> transaction(Future Function(Box box) transaction) async {
    var completer = Completer<void>();
    var completerFuture = completer.future;
    _runningTransactions.add(completerFuture);
    var trxBox = TransactionBox(this);
    await transaction(trxBox);
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
