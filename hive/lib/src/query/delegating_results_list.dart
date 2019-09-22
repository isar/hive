import 'package:hive/src/query/unmodifiable_results_list.dart';

abstract class DelegatingResultsList<E> extends UnmodifiableResultsList<E> {
  final List<E> resultItems = [];

  @override
  E get first => resultItems.first;

  @override
  E get last => resultItems.last;

  @override
  int get length => resultItems.length;

  @override
  List<E> operator +(List<E> other) => resultItems + other;

  @override
  E operator [](int index) => resultItems[index];

  @override
  bool any(bool Function(E element) test) => resultItems.any(test);

  @override
  Map<int, E> asMap() => resultItems.asMap();

  @override
  List<R> cast<R>() => resultItems.cast<R>();

  @override
  bool contains(Object element) => resultItems.contains(element);

  @override
  E elementAt(int index) => resultItems.elementAt(index);

  @override
  bool every(bool Function(E element) test) => resultItems.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      resultItems.expand<T>(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function() orElse}) =>
      resultItems.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      resultItems.fold<T>(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => resultItems.followedBy(other);

  @override
  void forEach(void Function(E element) f) => resultItems.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => resultItems.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => resultItems.indexOf(element);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      resultItems.indexWhere(test, start);

  @override
  bool get isEmpty => resultItems.isEmpty;

  @override
  bool get isNotEmpty => resultItems.isNotEmpty;

  @override
  Iterator<E> get iterator => resultItems.iterator;

  @override
  String join([String separator = '']) => resultItems.join(separator);

  @override
  int lastIndexOf(E element, [int start]) =>
      resultItems.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) =>
      resultItems.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) =>
      resultItems.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => resultItems.map<T>(f);

  @override
  E reduce(E Function(E value, E element) combine) =>
      resultItems.reduce(combine);

  @override
  Iterable<E> get reversed => resultItems.reversed;

  @override
  E get single => resultItems.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) =>
      resultItems.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => resultItems.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) =>
      resultItems.skipWhile(test);

  @override
  List<E> sublist(int start, [int end]) => resultItems.sublist(start, end);

  @override
  Iterable<E> take(int count) => resultItems.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) =>
      resultItems.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => resultItems.toList();

  @override
  Set<E> toSet() => resultItems.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => resultItems.where(test);

  @override
  Iterable<T> whereType<T>() => resultItems.whereType<T>();
}
