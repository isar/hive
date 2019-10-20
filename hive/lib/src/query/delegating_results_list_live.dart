import 'package:hive/src/query/unmodifiable_results_mixin.dart';
import 'package:hive/src/util/indexable_skip_list.dart';

abstract class DelegatingResultsListLive<E>
    extends UnmodifiableResultsMixin<E> {
  final IndexableSkipList<E, void> results;

  DelegatingResultsListLive(Comparator<E> comparator)
      : results = IndexableSkipList(comparator);

  @override
  E get first => results.getKeyAt(0);

  @override
  E get last => results.getKeyAt(results.length - 1);

  @override
  int get length => results.length;

  @override
  List<E> operator +(List<E> other) => results.keys.toList() + other;

  @override
  E operator [](int index) => results.getKeyAt(index);

  @override
  bool any(bool Function(E element) test) => results.keys.any(test);

  @override
  Map<int, E> asMap() {
    var map = <int, E>{};
    var i = 0;
    for (var element in this) {
      map[i++] = element;
    }
    return map;
  }

  @override
  List<R> cast<R>() => results.keys.cast<R>().toList();

  @override
  bool contains(Object element) => results.keys.contains(element);

  @override
  E elementAt(int index) => results.getKeyAt(index);

  @override
  bool every(bool Function(E element) test) => results.keys.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      results.keys.expand<T>(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function() orElse}) =>
      results.keys.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      results.keys.fold<T>(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => results.keys.followedBy(other);

  @override
  void forEach(void Function(E element) f) => results.keys.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => skip(start).take(end - start);

  @override
  int indexOf(E element, [int start = 0]) {
    var i = 0;
    for (var e in skip(start)) {
      if (e == element) return i;
      i++;
    }
    return -1;
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) {
    var i = 0;
    for (var element in skip(start)) {
      if (test(element)) return i;
      i++;
    }
    return -1;
  }

  @override
  bool get isEmpty => results.length == 0;

  @override
  bool get isNotEmpty => results.length != 0;

  @override
  Iterator<E> get iterator => results.keys.iterator;

  @override
  String join([String separator = '']) => results.keys.join(separator);

  @override
  int lastIndexOf(E element, [int start]) {
    var foundIndex = -1;
    var i = 0;
    for (var e in skip(start)) {
      if (element == e) foundIndex = i;
      i++;
    }
    return foundIndex;
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) {
    var foundIndex = -1;
    var i = 0;
    for (var element in skip(start)) {
      if (test(element)) foundIndex = i;
      i++;
    }
    return foundIndex;
  }

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) =>
      results.keys.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => results.keys.map<T>(f);

  @override
  E reduce(E Function(E value, E element) combine) =>
      results.keys.reduce(combine);

  @override
  Iterable<E> get reversed => results.keys.toList().reversed;

  @override
  E get single => results.keys.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) =>
      results.keys.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => results.keys.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
      results.keys.skipWhile(test);

  @override
  List<E> sublist(int start, [int end]) {
    var list = <E>[];
    var i = 0;
    for (var element in this) {
      if (i < start) {
        continue;
      } else if (i >= end) {
        break;
      }
      list.add(element);
      i++;
    }
    return list;
  }

  @override
  Iterable<E> take(int count) => results.keys.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
      results.keys.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => results.keys.toList();

  @override
  Set<E> toSet() => results.keys.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => results.keys.where(test);

  @override
  Iterable<T> whereType<T>() => results.keys.whereType<T>();
}
