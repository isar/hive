part of hive;

abstract class HiveQuery<E extends HiveObject> {
  const HiveQuery();

  HiveQuery<E> filter<T extends E>(Predicate<T> predicate);

  HiveQuery<E> exclude<T extends E>(Predicate<T> predicate);

  HiveQuery<E> limit(int limit);

  HiveQuery<E> order();

  HiveQuery<E> orderBy(
    ValueComparable<E> value, [
    Sorting sorting = Sorting.asc,
    ValueComparable<E> value2,
    Sorting sorting2,
    ValueComparable<E> value3,
    Sorting sorting3,
  ]);

  HiveQuery<E> orderWith(Comparator<E> comparator);

  HiveResults<E> findFirst({bool autoUpdate = false});

  HiveResults<E> findAll({bool autoUpdate = false});

  int count();
}

enum Sorting { asc, desc }

typedef Predicate<E> = bool Function(E item);

typedef ValueComparable<E> = Comparable Function(E item);
