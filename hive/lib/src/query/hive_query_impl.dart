import 'package:hive/hive.dart';

class HiveQueryImpl<T> extends HiveQuery<T> {
  final Box box;

  final List<Predicate> filters;

  final int itemLimit;

  factory HiveQueryImpl(Box box) {
    return HiveQueryImpl._(box, [if (T != dynamic) (item) => item is T], 0);
  }

  const HiveQueryImpl._(this.box, this.filters, this.itemLimit);

  @override
  HiveQuery filter<E>(Predicate<E> predicate) {
    Predicate<dynamic> filter;
    if (predicate is Predicate<dynamic>) {
      filter = predicate;
    } else {
      filter = (item) {
        return item is E && predicate(item);
      };
    }
    return HiveQueryImpl._(box, [...filters, filter], itemLimit);
  }

  @override
  HiveQuery exclude<E>(Predicate<E> predicate) {
    return filter<dynamic>((item) {
      return item is E && !predicate(item);
    });
  }

  @override
  HiveQuery limit(int limit) {
    return HiveQueryImpl._(box, filters, limit);
  }

  List<T> evaluate() {
    var newList = <T>[];
    itemLoop:
    for (var item in box.values) {
      for (var predicate in filters) {
        if (!predicate(item)) {
          continue itemLoop;
        }
      }
      newList.add(item as T);
    }
    return newList;
  }

  @override
  int count() => evaluate().length;
}
