part of hive;

abstract class HiveQuery<E extends HiveObject> {
  const HiveQuery();

  HiveQuery<E> filter<T extends E>(Predicate<T> predicate);

  HiveQuery<E> exclude<T extends E>(Predicate<T> predicate);

  HiveQuery<E> offset(int offset);

  HiveQuery<E> limit(int limit);

  HiveQuery<E> order([Sort sort = Sort.asc]);

  HiveQuery<E> orderBy(
    ValueComparable<E> value, [
    Sort sort = Sort.asc,
    ValueComparable<E> value2,
    Sort sort2,
    ValueComparable<E> value3,
    Sort sort3,
  ]);

  HiveQuery<E> orderWith(Comparator<E> comparator, [Sort sort = Sort.asc]);

  HiveResults<E> find({bool autoUpdate = false});

  int count();
}

enum Sort { asc, desc }

typedef Predicate<E> = bool Function(E item);

typedef ValueComparable<E> = Comparable Function(E item);
