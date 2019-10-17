import 'package:hive/src/query/unmodifiable_results_list.dart';

abstract class DelegatingResultsList<E> extends UnmodifiableResultsList<E> {
  final List<E> results = [];

  @override
  E get first => results.first;

  @override
  E get last => results.last;

  @override
  int get length => results.length;

  @override
  List<E> operator +(List<E> other) => results + other;

  @override
  E operator [](int index) => results[index];

  @override
  bool any(bool Function(E element) test) => results.any(test);

  @override
  Map<int, E> asMap() => results.asMap();

  @override
  List<R> cast<R>() => results.cast<R>();

  @override
  bool contains(Object element) => results.contains(element);

  @override
  E elementAt(int index) => results.elementAt(index);

  @override
  bool every(bool Function(E element) test) => results.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      results.expand<T>(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function() orElse}) =>
      results.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      results.fold<T>(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => results.followedBy(other);

  @override
  void forEach(void Function(E element) f) => results.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) => results.getRange(start, end);

  @override
  int indexOf(E element, [int start = 0]) => results.indexOf(element);

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) =>
      results.indexWhere(test, start);

  @override
  bool get isEmpty => results.isEmpty;

  @override
  bool get isNotEmpty => results.isNotEmpty;

  @override
  Iterator<E> get iterator => results.iterator;

  @override
  String join([String separator = '']) => results.join(separator);

  @override
  int lastIndexOf(E element, [int start]) =>
      results.lastIndexOf(element, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) =>
      results.lastIndexWhere(test, start);

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) =>
      results.lastWhere(test, orElse: orElse);

  @override
  Iterable<T> map<T>(T Function(E e) f) => results.map<T>(f);

  @override
  E reduce(E Function(E value, E element) combine) => results.reduce(combine);

  @override
  Iterable<E> get reversed => results.reversed;

  @override
  E get single => results.single;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) =>
      results.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => results.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => results.skipWhile(test);

  @override
  List<E> sublist(int start, [int end]) => results.sublist(start, end);

  @override
  Iterable<E> take(int count) => results.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E value) test) => results.takeWhile(test);

  @override
  List<E> toList({bool growable = true}) => results.toList();

  @override
  Set<E> toSet() => results.toSet();

  @override
  Iterable<E> where(bool Function(E element) test) => results.where(test);

  @override
  Iterable<T> whereType<T>() => results.whereType<T>();
}
