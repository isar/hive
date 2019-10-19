import 'package:hive/hive.dart';
import 'package:hive/src/query/hive_query_impl.dart';

abstract class HiveResultsMixin<E extends HiveObject>
    implements HiveResults<E> {
  @override
  Box get box => (query as HiveQueryImpl).box;

  @override
  Iterable<dynamic> get keys sync* {
    for (var value in this) {
      yield value.key;
    }
  }

  @override
  Future<void> deleteAllFromHive() {
    return box.deleteAll(keys);
  }

  @override
  Future<void> deleteFirstFromHive() {
    return first.delete();
  }

  @override
  Future<void> deleteLastFromHive() {
    return last.delete();
  }

  @override
  Future<void> deleteFromHive(int index) {
    return this[index].delete();
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var item in this) {
      map[item.key] = item;
    }
    return map;
  }
}
