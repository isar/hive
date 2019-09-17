import 'package:hive/hive.dart';
import 'package:hive/src/query/hive_results_impl.dart';

int _dynamicCompare(dynamic a, dynamic b) =>
    Comparable.compare(a as Comparable, b as Comparable);

Comparator<E> _defaultCompare<E>() {
  // If K <: Comparable, then we can just use Comparable.compare
  // with no casts.
  Object compare = Comparable.compare;
  if (compare is Comparator<E>) {
    return compare;
  }
  // Otherwise wrap and cast the arguments on each call.
  return _dynamicCompare;
}

class HiveQueryImpl<E extends HiveObject> extends HiveQuery<E> {
  final Box box;

  final List<Predicate<E>> filters;

  final int itemLimit;

  final Comparator<E> sortingComparator;

  factory HiveQueryImpl(Box box) {
    return HiveQueryImpl._(box, [], null, null);
  }

  const HiveQueryImpl._(
      this.box, this.filters, this.itemLimit, this.sortingComparator);

  @override
  HiveQuery<E> filter<T extends E>(Predicate<T> predicate) {
    Predicate<E> filter;
    if (predicate is Predicate<E>) {
      filter = predicate;
    } else {
      filter = (item) {
        if (item is T) {
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
  HiveQuery<E> exclude<T extends E>(Predicate<T> predicate) {
    return filter<E>((item) {
      return item is T && !predicate(item);
    });
  }

  @override
  HiveQueryImpl<E> order() {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }
    return HiveQueryImpl._(box, filters, itemLimit, _defaultCompare<E>());
  }

  @override
  HiveQuery<E> orderBy(
    ValueComparable<E> value, [
    Sorting sorting = Sorting.asc,
    ValueComparable<E> value2,
    Sorting sorting2 = Sorting.asc,
    ValueComparable<E> value3,
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
    Comparator<E> comparator;
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
        var result = sort * value(a).compareTo(value(b));
        return result;
      };
    }
    return HiveQueryImpl._(box, filters, itemLimit, comparator);
  }

  @override
  HiveQuery<E> orderWith(Comparator<E> comparator) {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }
    return HiveQueryImpl._(box, filters, itemLimit, comparator);
  }

  @override
  HiveQuery<E> limit(int limit) {
    if (itemLimit != null) {
      throw HiveError('A limit is already specified.');
    }
    return HiveQueryImpl._(box, filters, limit, sortingComparator);
  }

  List<E> evaluate() {
    var newList = <E>[];
    var values = box.values;
    itemLoop:
    for (var item in values) {
      if (item is E) {
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

  @override
  HiveResults<E> findFirst({bool autoUpdate = false}) {
    return HiveQueryImpl<E>._(box, filters, 1, sortingComparator).findAll();
  }

  @override
  HiveResults<E> findAll({bool autoUpdate = false}) {
    return HiveResultsImpl<E>(this);
  }

  @override
  int count() => evaluate().length;
}
