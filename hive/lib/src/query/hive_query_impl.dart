import 'package:hive/hive.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/query/hive_results_impl.dart';
import 'package:hive/src/query/hive_results_live_impl.dart';

class HiveQueryImpl<E extends HiveObject> extends HiveQuery<E> {
  final Box box;

  final List<Predicate<E>> filters;

  final int resultOffset;

  final int resultLimit;

  final Comparator<E> sortingComparator;

  factory HiveQueryImpl(Box box) {
    return HiveQueryImpl._(box, [], null, null, null);
  }

  const HiveQueryImpl._(this.box, this.filters, this.resultOffset,
      this.resultLimit, this.sortingComparator);

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
    return HiveQueryImpl._(box, [...filters, filter], resultOffset, resultLimit,
        sortingComparator);
  }

  @override
  HiveQuery<E> exclude<T extends E>(Predicate<T> predicate) {
    return filter<E>((item) {
      return item is T && !predicate(item);
    });
  }

  @override
  HiveQueryImpl<E> order([Sort sort = Sort.asc]) {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }

    var sortMultiplier = sort == Sort.asc ? 1 : -1;
    var comparator = (E a, E b) {
      var result = sortMultiplier * (a as Comparable).compareTo(b);
      if (result == 0) {
        return compareKeys(a.key, b.key);
      } else {
        return result;
      }
    };
    return HiveQueryImpl._(box, filters, resultOffset, resultLimit, comparator);
  }

  @override
  HiveQuery<E> orderBy(
    ValueComparable<E> value, [
    Sort sort = Sort.asc,
    ValueComparable<E> value2,
    Sort sort2 = Sort.asc,
    ValueComparable<E> value3,
    Sort sort3 = Sort.asc,
  ]) {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }
    var sortMultiplier = sort == Sort.asc ? 1 : -1;
    var sortMultiplier2 = sort2 == Sort.asc ? 1 : -1;
    var sortMultiplier3 = sort3 == Sort.asc ? 1 : -1;
    Comparator<E> comparator;
    if (value3 != null) {
      comparator = (a, b) {
        var result = sortMultiplier * value(a).compareTo(value(b));
        if (result == 0) {
          result = sortMultiplier2 * value2(a).compareTo(value2(b));
          if (result == 0) {
            result = sortMultiplier3 * value3(a).compareTo(value3(b));
            if (result == 0) {
              result = compareKeys(a.key, b.key);
            }
          }
        }
        return result;
      };
    } else if (value2 != null) {
      comparator = (a, b) {
        var result = sortMultiplier * value(a).compareTo(value(b));
        if (result == 0) {
          result = sortMultiplier2 * value2(a).compareTo(value2(b));
          if (result == 0) {
            result = compareKeys(a.key, b.key);
          }
        }
        return result;
      };
    } else {
      comparator = (a, b) {
        var result = sortMultiplier * value(a).compareTo(value(b));
        if (result == 0) {
          return compareKeys(a.key, b.key);
        } else {
          return result;
        }
      };
    }
    return HiveQueryImpl._(box, filters, resultOffset, resultLimit, comparator);
  }

  @override
  HiveQuery<E> orderWith(Comparator<E> comparator, [Sort sort = Sort.asc]) {
    if (sortingComparator != null) {
      throw HiveError('An order is already specified.');
    }

    var sortMultiplier = sort == Sort.asc ? 1 : -1;
    var sortedComparator = (E a, E b) {
      var result = sortMultiplier * comparator(a, b);
      if (result == 0) {
        return compareKeys(a.key, b.key);
      } else {
        return result;
      }
    };
    return HiveQueryImpl._(
        box, filters, resultOffset, resultLimit, sortedComparator);
  }

  @override
  HiveQuery<E> offset(int offset) {
    if (resultOffset != null) {
      throw HiveError('An offset is already specified.');
    }
    return HiveQueryImpl._(
        box, filters, offset, resultLimit, sortingComparator);
  }

  @override
  HiveQuery<E> limit(int limit) {
    if (resultLimit != null) {
      throw HiveError('A limit is already specified.');
    }
    return HiveQueryImpl._(
        box, filters, resultOffset, limit, sortingComparator);
  }

  void evaluate(List<E> results, num offset, [num limit = 999999999]) {
    valueLoop:
    for (var value in box.values) {
      if (value is E) {
        for (var predicate in filters) {
          if (!predicate(value)) {
            continue valueLoop;
          }
        }

        if (offset-- <= 0) {
          results.add(value);
        }

        if (results.length >= limit) {
          break;
        }
      }
    }
  }

  @override
  HiveResults<E> find({bool autoUpdate = false}) {
    if (autoUpdate) {
      return HiveResultsLiveImpl<E>(this);
    } else {
      return HiveResultsImpl<E>(this);
    }
  }

  @override
  int count() {
    var results = <E>[];
    evaluate(results, 0);
    return results.length;
  }
}
