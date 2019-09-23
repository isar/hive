import 'package:hive/hive.dart';
import 'package:hive/src/query/delegating_results_list_live.dart';
import 'package:hive/src/query/hive_query_impl.dart';

class HiveResultsLiveImpl<E extends HiveObject>
    extends DelegatingResultsListLive<E> implements HiveResults<E> {
  final HiveQueryImpl<E> _query;

  HiveResultsLiveImpl(this._query) : super(_query.sortingComparator) {
    refresh();
  }

  @override
  HiveQuery<E> get query => _query;

  @override
  Box get box => _query.box;

  @override
  List<dynamic> get keys {
    var keys = List(results.length);
    var i = 0;
    for (var item in results.keys) {
      keys[i++] = item.key;
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
    throw UnsupportedError(
        'Auto updating HiveResilts must not be refreshed manually.');
  }

  @override
  Map<dynamic, E> toMap() {
    var map = <dynamic, E>{};
    for (var item in results.keys) {
      map[item.key] = item;
    }
    return map;
  }

  @override
  void close() {}

  @override
  Stream<HiveResults<E>> watch() {
    // TODO: implement watch
    return null;
  }

  @override
  Stream<E> watchFirst() {
    // TODO: implement watchFirst
    return null;
  }

  @override
  Stream<E> watchLast() {
    // TODO: implement watchLast
    return null;
  }
}
