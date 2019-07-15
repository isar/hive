import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/box/transaction_box.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

abstract class BoxBase extends TypeRegistryImpl implements Box {
  List<Future> _runningTransactions = List();

  BoxBase(TypeRegistry parent) : super(parent);

  @override
  Future operator [](String key) => get(key);

  @override
  Future<void> transaction(Future Function(Box box) transaction) async {
    var completer = Completer();
    var completerFuture = completer.future;
    _runningTransactions.add(completerFuture);
    var trxBox = TransactionBox(this);
    await transaction(trxBox);
    await trxBox.commit();
    completer.complete();
    _runningTransactions.remove(completerFuture);
  }

  @protected
  Future waitForRunningTransactions() {
    return Future.wait(_runningTransactions);
  }
}
