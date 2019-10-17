import 'package:hive/hive.dart';
import 'package:hive/src/query/delegating_results_list.dart';
import 'package:hive/src/query/hive_query_impl.dart';

class HiveResultsImpl<E extends HiveObject> extends DelegatingResultsList<E>
    implements HiveResults<E> {
  final HiveQueryImpl<E> _query;

  HiveResultsImpl(this._query) {
    refresh();
  }

  @override
  HiveQuery<E> get query => _query;

  @override
  Box get box => _query.box;

  @override
  List<dynamic> get keys {
    var keys = List(results.length);
    for (var i = 0; i < results.length; i++) {
      keys[i] = results[i].key;
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
    results.clear();
    _query.evaluate(results, _query.resultOffset, _query.resultLimit);
    if (_query.sortingComparator != null) {
      results.sort(_query.sortingComparator);
    }
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var item in results) {
      map[item.key] = item;
    }
    return map;
  }

  @override
  Stream<HiveResults<E>> watch() {
    throw UnsupportedError('Only auto updating HiveResults watching.');
  }

  @override
  Stream<E> watchFirst() {
    throw UnsupportedError('Only auto updating HiveResults watching.');
  }

  @override
  Stream<E> watchLast() {
    throw UnsupportedError('Only auto updating HiveResults watching.');
  }

  @override
  void close() {}
}
