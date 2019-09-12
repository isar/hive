part of hive;

abstract class QueryResult<T> {
  List<dynamic> get keys;

  List<T> get values;

  bool get isEmpty;

  bool get isNotEmpty;

  int get length;

  Future<void> deleteAll();

  void refresh();

  Map<dynamic, T> toMap();

  void close();
}

typedef Update<T> = T Function(dynamic key, T value);
