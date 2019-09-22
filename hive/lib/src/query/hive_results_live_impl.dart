import 'package:hive/hive.dart';
import 'package:hive/src/query/delegating_results_list_live.dart';
import 'package:hive/src/query/hive_query_impl.dart';
import 'package:hive/src/util/indexable_skip_list.dart';

class HiveResultsLiveImpl<E extends HiveObject>
    extends DelegatingResultsListLive<E> implements HiveResults<E> {
  final HiveQueryImpl<E> _query;

  HiveResultsLiveImpl(this._query) {
    refresh();
  }

  @override
  HiveQuery<E> get query => _query;

  @override
  Box get box => _query.box;

  @override
  List<dynamic> get keys {
    var keys = List(resultItems.length);
    var i = 0;
    for (var item in resultItems.keys) {
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
    for (var item in resultItems.keys) {
      map[item.key] = item;
    }
    return map;
  }

  @override
  void close() {}

  @override
  // TODO: implement resultItems
  IndexableSkipList<E, void> get resultItems => null;

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
