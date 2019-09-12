part of hive;

abstract class HiveQuery<T> {
  const HiveQuery();

  HiveQuery filter<E>(Predicate<E> predicate);

  HiveQuery exclude<E>(Predicate<E> predicate);

  HiveQuery limit(int limit);

  int count();
}

typedef Predicate<E> = bool Function(E item);
