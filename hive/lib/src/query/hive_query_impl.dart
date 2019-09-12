import 'package:hive/hive.dart';
import 'package:hive/src/query/query_result_impl.dart';

int _dynamicCompare(dynamic a, dynamic b) =>
    Comparable.compare(a as Comparable, b as Comparable);

Comparator<T> _defaultCompare<T>() {
  // If K <: Comparable, then we can just use Comparable.compare
  // with no casts.
  Object compare = Comparable.compare;
  if (compare is Comparator<T>) {
    return compare;
  }
  // Otherwise wrap and cast the arguments on each call.
  return _dynamicCompare;
}

class HiveQueryImpl<T extends HiveObject> extends HiveQuery<T> {
  final Box box;

  final List<Predicate<T>> filters;

  final int itemLimit;

  final Comparator<T> sortingComparator;

  factory HiveQueryImpl(Box box) {
    return HiveQueryImpl._(box, [], null, null);
  }

  const HiveQueryImpl._(
      this.box, this.filters, this.itemLimit, this.sortingComparator);

  @override
  HiveQuery<T> filter<E extends T>(Predicate<E> predicate) {
    Predicate<T> filter;
    if (predicate is Predicate<T>) {
      filter = predicate;
    } else {
      filter = (item) {
        if (item is E) {
          return predicate(item);
        } else {
          return true;
        }
      };
    }
    return HiveQueryImpl._(
        box, [...filters, filter], itemLimit, sortingComparator);
  }

  @override
  HiveQuery<T> exclude<E extends T>(Predicate<E> predicate) {
    return filter<T>((item) {
      return item is E && !predicate(item);
    });
  }

  @override
  HiveQueryImpl<T> order() {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }
    return HiveQueryImpl._(box, filters, itemLimit, _defaultCompare<T>());
  }

  @override
  HiveQuery<T> orderBy(
    ValueComparable<T> value, [
    Sorting sorting = Sorting.asc,
    ValueComparable<T> value2,
    Sorting sorting2 = Sorting.asc,
    ValueComparable<T> value3,
    Sorting sorting3 = Sorting.asc,
  ]) {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }
    var sort = 1;
    if (sorting == Sorting.desc) {
      sort = -1;
    }
    var sort2 = 1;
    if (sorting2 == Sorting.desc) {
      sort2 = -1;
    }
    var sort3 = 1;
    if (sorting3 == Sorting.desc) {
      sort3 = -1;
    }
    Comparator<T> comparator;
    if (value3 != null) {
      comparator = (a, b) {
        var result = sort * value(a).compareTo(value(b));
        if (result == 0) {
          result = sort2 * value2(a).compareTo(value2(b));
          if (result == 0) {
            result = sort3 * value3(a).compareTo(value3(b));
          }
        }
        return result;
      };
    } else if (value2 != null) {
      comparator = (a, b) {
        var result = sort * value(a).compareTo(value(b));
        if (result == 0) {
          result = sort2 * value2(a).compareTo(value2(b));
        }
        return result;
      };
    } else {
      comparator = (a, b) {
        return sort * value(a).compareTo(value(b));
      };
    }
    return HiveQueryImpl._(box, filters, itemLimit, comparator);
  }

  @override
  HiveQuery<T> orderWith(Comparator<T> comparator) {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }
    return HiveQueryImpl._(box, filters, itemLimit, comparator);
  }

  @override
  HiveQuery<T> limit(int limit) {
    if (itemLimit != null) {
      throw HiveError('A limit is already specified.');
    }
    return HiveQueryImpl._(box, filters, limit, sortingComparator);
  }

  List<T> evaluate() {
    var newList = <T>[];
    var values = box.values;
    itemLoop:
    for (var item in values) {
      if (item is T) {
        for (var predicate in filters) {
          if (!predicate(item)) {
            continue itemLoop;
          }
        }
        newList.add(item);
        if (itemLimit != null && newList.length == itemLimit) {
          break;
        }
      }
    }
    return newList;
  }

  List<T> evaluateSorted() {
    var list = evaluate();
    if (sortingComparator != null) {
      list.sort(sortingComparator);
    }
    return list;
  }

  @override
  QueryResult<T> findFirst() {
    return HiveQueryImpl<T>._(box, filters, 1, sortingComparator).findAll();
  }

  @override
  QueryResult<T> findAll() {
    return QueryResultImpl(this, evaluateSorted());
  }

  @override
  QueryResult<T> watchFirst() {
    return HiveQueryImpl<T>._(box, filters, 1, sortingComparator).watchFirst();
  }

  @override
  QueryResult<T> watchAll() {}

  @override
  int count() => evaluate().length;
}
