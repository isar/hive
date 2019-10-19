part of hive;

/// [LazyBox]es don't keep the values in memory like normal boxes. Each time a
/// value is read, it is loaded from the backend.
abstract class LazyBox extends Box {
  /// Not supported for lazy boxes.
  @override
  Iterable get values;

  @override
  Future<dynamic> get(dynamic key, {dynamic defaultValue});

  @override
  Future<dynamic> getAt(int index);

  /// Not supported for lazy boxes.
  @override
  HiveQuery<T> query<T extends HiveObject>();

  /// Not supported for lazy boxes.
  @override
  Map<dynamic, dynamic> toMap();
}
