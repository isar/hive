import 'package:hive/hive.dart';
import 'package:hive/src/box/transaction_base.dart';

class LazyTransaction extends TransactionBase<LazyBox> implements LazyBox {
  @override
  final lazy = true;

  LazyTransaction(LazyBox box, int Function() autoIncrement)
      : super(box, autoIncrement);

  @override
  Future<dynamic> get(dynamic key, {dynamic defaultValue}) {
    if (newEntries.containsKey(key)) {
      return Future.value(newEntries[key] ?? defaultValue);
    } else {
      return box.get(key, defaultValue: defaultValue);
    }
  }

  @override
  Future<Map<dynamic, dynamic>> toMap() async {
    var map = await box.toMap();
    map
      ..addAll(newEntries)
      ..removeWhere((key, val) => val == null);
    return map;
  }

  @override
  TransactionBase<LazyBox> getTransaction() {
    return LazyTransaction(this, autoIncrement);
  }
}
