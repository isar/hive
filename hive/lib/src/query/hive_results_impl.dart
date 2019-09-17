import 'package:hive/hive.dart';
import 'package:hive/src/query/delegating_results_list.dart';
import 'package:hive/src/query/hive_query_impl.dart';

class HiveResultsImpl<E extends HiveObject> extends DelegatingResultsList<E>
    implements HiveResults<E> {
  final HiveQueryImpl<E> _query;

  @override
  List<E> resultItems;

  HiveResultsImpl(this._query) {
    refresh();
  }

  @override
  Box get box => _query.box;

  @override
  List<dynamic> get keys {
    var keys = List(resultItems.length);
    for (var i = 0; i < resultItems.length; i++) {
      keys[i] = resultItems[i].key;
    }
    return keys;
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
  void refresh() {
    resultItems = _query.evaluate();
    if (_query.sortingComparator != null) {
      resultItems.sort(_query.sortingComparator);
    }
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var item in resultItems) {
      map[item.key] = item;
    }
    return map;
  }

  @override
  Stream<HiveResults<E>> watch() {
    throw UnsupportedError('Only auto updating HiveResults watching.');
  }

  @override
  void close() {}
}
