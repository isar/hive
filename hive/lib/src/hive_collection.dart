part of hive;

abstract class HiveCollection<E extends HiveObject> implements List<E> {
  Box get box;

  Iterable<dynamic> get keys;

  Future<void> deleteAllFromHive();

  Future<void> deleteFirstFromHive();

  Future<void> deleteLastFromHive();

  Future<void> deleteFromHive(int index);

  Map<dynamic, E> toMap();
}
