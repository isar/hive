part of hive;

abstract class HiveList<E extends HiveObject> extends HiveCollection<E>
    implements List<E> {
  factory HiveList(HiveObject hiveObject, Box box, {List<E> objects}) =>
      HiveListImpl(hiveObject, box, objects: objects);

  @protected
  void link(HiveObject object);

  void dispose();

  HiveList<T> castHiveList<T extends HiveObject>();
}
