part of hive;

abstract class HiveResults<E extends HiveObject> implements List<E> {
  HiveQuery<E> get query;

  Box get box;

  Iterable<dynamic> get keys;

  Future<void> deleteAllFromHive();

  Future<void> deleteFirstFromHive();

  Future<void> deleteLastFromHive();

  Future<void> deleteFromHive(int index);

  void refresh();

  Map<dynamic, E> toMap();

  Stream<HiveResults<E>> watch();

  Stream<E> watchFirst();

  Stream<E> watchLast();

  void close();
}
