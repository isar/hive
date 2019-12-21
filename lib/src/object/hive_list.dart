part of hive;

abstract class HiveList<E extends HiveObject> extends HiveCollection<E> {
  factory HiveList(HiveObject hiveObject, Box box, {List<E> objects}) =>
      HiveListImpl(hiveObject, box, objects: objects);

  void dispose();

  HiveList<T> castHiveList<T extends HiveObject>();
}
