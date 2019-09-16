import 'package:hive/src/query/unmodifiable_results_list.dart';
import 'package:hive/src/util/indexable_skip_list.dart';

abstract class DelegatingResultsListLive<E> extends UnmodifiableResultsList<E> {
  IndexableSkipList<E, void> get resultItems;

  @override
  E get first => resultItems.getKeyAt(0);

  @override
  E get last => resultItems.getKeyAt(resultItems.length - 1);

  @override
  int get length => resultItems.length;

  @override
  List<E> operator +(List<E> other) => resultItems.keys.toList() + other;

  @override
  E operator [](int index) => resultItems.getKeyAt(index);

  @override
  bool any(bool Function(E element) test) => resultItems.keys.any(test);

  @override
  Map<int, E> asMap() => resultItems.keys.asMap();

  @override
  List<R> cast<R>() => resultItems.keys.cast<R>().toList();

  @override
  bool contains(Object element) => resultItems.keys.contains(element);

  @override
  E elementAt(int index) => resultItems.getKeyAt(index);

  @override
  bool every(bool Function(E element) test) => resultItems.keys.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      resultItems.keys.expand<T>(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function() orElse}) =>
      resultItems.keys.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      resultItems.keys.fold<T>(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) =>
      resultItems.keys.followedBy(other);

  @override
  void forEach(void Function(E element) f) => resultItems.keys.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) =>
      resultItems.keys.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => resultItems.keys.indexOf(element);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      resultItems.keys.indexWhere(test, start);

  @override
  bool get isEmpty => resultItems.length == 0;

  @override
  bool get isNotEmpty => resultItems.length != 0;

  @override
  Iterator<E> get iterator => resultItems.keys.iterator;

  @override
  String join([String separator = '']) => resultItems.keys.join(separator);

  @override
  int lastIndexOf(E element, [int start]) =>
      resultItems.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) =>
      resultItems.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) =>
      resultItems.keys.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => resultItems.keys.map<T>(f);

  @override
  E reduce(E Function(E value, E element) combine) =>
      resultItems.keys.reduce(combine);

  @override
  Iterable<E> get reversed => resultItems.keys.toList().reversed;

  @override
  E get single => resultItems.keys.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) =>
      resultItems.keys.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => resultItems.keys.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
      resultItems.keys.skipWhile(test);

  @override
  List<E> sublist(int start, [int end]) => resultItems.sublist(start, end);

  @override
  Iterable<E> take(int count) => resultItems.keys.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
      resultItems.keys.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => resultItems.keys.toList();

  @override
  Set<E> toSet() => resultItems.keys.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) =>
      resultItems.keys.where(test);

  @override
  Iterable<T> whereType<T>() => resultItems.keys.whereType<T>();
}
