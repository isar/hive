import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/hive_collection_mixin.dart';
import 'package:hive/src/query/delegating_results_list_live.dart';
import 'package:hive/src/query/hive_query_impl.dart';
import 'package:hive/src/query/unmodifiable_results_mixin.dart';

class HiveResultsLiveImpl<E extends HiveObject>
    extends DelegatingResultsListLive<E>
    with HiveCollectionMixin<E>, UnmodifiableResultsMixin<E>
    implements HiveResults<E> {
  final HiveQueryImpl<E> _query;

  HiveResultsLiveImpl(this._query) : super(_query.sortingComparator) {
    refresh();
  }

  @override
  Box get box => _query.box;

  @override
  HiveQuery<E> get query => _query;

  @override
  void refresh() {
    throw UnsupportedError(
        'Auto updating HiveResilts must not be refreshed manually.');
  }

  void updateAdd(List<Frame> frames) {
    for (var frame in frames) {
      if (frame.deleted) {
        //results.delete(frame.value);
      }
    }
  }

  void updateDelete(Frame frame) {
    var value = frame.value;
    if (value is E) {
      results.delete(value);
    }
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
