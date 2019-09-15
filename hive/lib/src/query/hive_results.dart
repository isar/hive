part of hive;

abstract class HiveResults<E extends HiveObject> implements List<E> {
  List<dynamic> get keys;

  Box get box;

  Future<void> deleteAllFromHive();

  Future<void> deleteFirstFromHive();

  Future<void> deleteLastFromHive();

  Future<void> deleteFromHive(int index);

  void refresh();

  Map<dynamic, E> toMap();

  void addChangeListener();

  void removeChangeListener();

  void removeAllChangeListeners();

  void close();
}
