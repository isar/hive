import 'package:hive/hive.dart';
import 'package:hive/src/query/hive_query_impl.dart';

class QueryResultImpl<T extends HiveObject> extends QueryResult<T> {
  final HiveQueryImpl<T> _query;
  List<T> cachedItems;

  QueryResultImpl(this._query, this.cachedItems);

  @override
  List<dynamic> get keys {
    var keys = List(cachedItems.length);
    for (var i = 0; i < cachedItems.length; i++) {
      keys[i] = cachedItems[i].key;
    }
    return keys;
  }

  @override
  List<T> get values {
    return cachedItems.toList();
  }

  @override
  bool get isEmpty => cachedItems.isEmpty;

  @override
  bool get isNotEmpty => cachedItems.isNotEmpty;

  @override
  int get length => cachedItems.length;

  @override
  Future<void> deleteAll() {
    return _query.box.deleteAll(keys);
  }

  @override
  void refresh() {
    cachedItems = _query.evaluateSorted();
  }

  @override
  Map<dynamic, T> toMap() {
    var map = <dynamic, T>{};
    for (var item in cachedItems) {
      map[item.key] = item;
    }
    return map;
  }

  @override
  void close() {}
}
