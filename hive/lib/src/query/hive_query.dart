part of hive;

abstract class HiveQuery<T extends HiveObject> {
  const HiveQuery();

  HiveQuery<T> filter<E extends T>(Predicate<E> predicate);

  HiveQuery<T> exclude<E extends T>(Predicate<E> predicate);

  HiveQuery<T> limit(int limit);

  HiveQuery<T> order();

  HiveQuery<T> orderBy(
    ValueComparable<T> value, [
    Sorting sorting = Sorting.asc,
    ValueComparable<T> value2,
    Sorting sorting2,
    ValueComparable<T> value3,
    Sorting sorting3,
  ]);

  HiveQuery<T> orderWith(Comparator<T> comparator);

  QueryResult<T> findFirst();

  QueryResult<T> findAll();

  QueryResult<T> watchFirst();

  QueryResult<T> watchAll();

  int count();
}

enum Sorting { asc, desc }

typedef Predicate<T> = bool Function(T item);

typedef ValueComparable<T> = Comparable Function(T item);
