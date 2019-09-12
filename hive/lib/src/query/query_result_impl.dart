import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/query/hive_query_impl.dart';

class QueryResultImpl<T> extends QueryResult<T> {
  HiveQueryImpl _query;
  List<Frame> cachedFrames;

  @override
  List<dynamic> get keys {
    var keys = List(cachedFrames.length);
    for (var i = 0; i < cachedFrames.length; i++) {
      keys[i] = cachedFrames[i].key;
    }
    return keys;
  }

  @override
  List<T> get values {
    var values = List<T>(cachedFrames.length);
    for (var i = 0; i < cachedFrames.length; i++) {
      values[i] = cachedFrames[i].value as T;
    }
    return values;
  }

  @override
  bool get isEmpty => cachedFrames.isEmpty;

  @override
  bool get isNotEmpty => cachedFrames.isNotEmpty;

  @override
  int get length => cachedFrames.length;

  @override
  Future<void> deleteAll() {
    return _query.box.deleteAll(keys);
  }

  @override
  Future<void> updateAll() {
    return _query.box.putAll(toMap());
  }

  void refresh() {
    //cachedFrames =
  }

  @override
  Map<dynamic, T> toMap() {
    var map = <dynamic, T>{};
    for (var frame in cachedFrames) {
      map[frame.key] = frame.value as T;
    }
    return map;
  }

  @override
  void close() {}
}
