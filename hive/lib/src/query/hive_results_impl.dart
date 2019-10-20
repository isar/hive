import 'package:hive/hive.dart';
import 'package:hive/src/hive_collection_mixin.dart';
import 'package:hive/src/query/hive_query_impl.dart';
import 'package:hive/src/query/unmodifiable_results_mixin.dart';
import 'package:hive/src/util/delegating_list_view_mixin.dart';

class HiveResultsImpl<E extends HiveObject>
    with
        HiveCollectionMixin<E>,
        DelegatingListViewMixin<E>,
        UnmodifiableResultsMixin<E>
    implements HiveResults<E> {
  final HiveQueryImpl<E> _query;

  List<E> _results;

  HiveResultsImpl(this._query) {
    refresh();
  }

  @override
  Box get box => _query.box;

  @override
  HiveQuery<E> get query => _query;

  @override
  List<E> get delegate => _results;

  @override
  void refresh() {
    _results = [];
    _query.evaluate(_results, _query.resultOffset, _query.resultLimit);
    if (_query.sortingComparator != null) {
      _results.sort(_query.sortingComparator);
    }
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
