part of hive;

/// [LazyBox]es don't keep the values in memory like normal boxes. Each time a
/// value is read, it is loaded from the backend.
abstract class LazyBox<E> extends BoxBase<E> {
  Future<E> get(dynamic key, {E defaultValue});

  Future<E> getAt(int index);
}
