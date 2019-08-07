part of hive;

abstract class LazyBox extends Box {
  @override
  Future<dynamic> get(dynamic key, {dynamic defaultValue});

  @override
  Future<Map<dynamic, dynamic>> toMap();

  Future<void> transaction(Future Function(LazyBox box) transaction);
}
