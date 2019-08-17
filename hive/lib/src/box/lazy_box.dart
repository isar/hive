part of hive;

abstract class LazyBox extends Box {
  @override
  Future<dynamic> get(dynamic key, {dynamic defaultValue});

  @override
  Future<dynamic> getAt(int index, {dynamic defaultValue});
}
