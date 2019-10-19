import 'package:hive/hive.dart';
import 'package:hive/src/query/delegating_results_list.dart';
import 'package:hive/src/query/hive_query_impl.dart';
import 'package:hive/src/query/hive_results_base.dart';

class HiveResultsImpl<E extends HiveObject> extends DelegatingResultsList<E>
    with HiveResultsMixin<E> {
  final HiveQueryImpl<E> _query;

  HiveResultsImpl(this._query) {
    refresh();
  }

  @override
  HiveQuery<E> get query => _query;

  @override
  void refresh() {
    results.clear();
    _query.evaluate(results, _query.resultOffset, _query.resultLimit);
    if (_query.sortingComparator != null) {
      results.sort(_query.sortingComparator);
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
