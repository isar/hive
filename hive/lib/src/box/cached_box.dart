part of hive;

abstract class CachedBox extends Box {
  Iterable<dynamic> get values;

  dynamic operator [](dynamic key);

  void operator []=(dynamic key, dynamic value);

  @override
  Map<dynamic, dynamic> toMap();

  Future<void> transaction(Future Function(CachedBox box) transaction);
}
