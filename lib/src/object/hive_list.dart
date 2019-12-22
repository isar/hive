part of hive;

@experimental
abstract class HiveList<E extends HiveObject> extends HiveCollection<E>
    implements List<E> {
  factory HiveList(Box box, {List<E> objects}) =>
      HiveListImpl(box, objects: objects);

  void dispose();

  HiveList<T> castHiveList<T extends HiveObject>();
}
