import 'package:hive/hive.dart';
import 'package:hive/src/box/transaction_base.dart';

class CachedTransaction extends TransactionBase<CachedBox>
    implements CachedBox {
  @override
  final lazy = false;

  CachedTransaction(CachedBox box, int Function() autoIncrement)
      : super(box, autoIncrement);

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    if (newEntries.containsKey(key)) {
      return Future.value(newEntries[key] ?? defaultValue);
    } else {
      return box.get(key, defaultValue: defaultValue);
    }
  }

  @override
  operator [](key) {
    return get(key);
  }

  @override
  void operator []=(key, value) {
    put(key, value);
  }

  @override
  Iterable get values => null;

  @override
  Map<dynamic, dynamic> toMap() {
    var map = box.toMap();
    map
      ..addAll(newEntries)
      ..removeWhere((key, val) => val == null);
    return map;
  }

  @override
  TransactionBase<CachedBox> getTransaction() {
    return CachedTransaction(this, autoIncrement);
  }
}
