import 'dart:math';

abstract class DelegatingResultList<E> implements List<E> {
  final _writeUnsupported = UnsupportedError('HiveResults cannot be modified.');

  List<E> get resultItems;

  @override
  E get first => resultItems.first;

  @override
  set first(E first) => throw _writeUnsupported;

  @override
  E get last => resultItems.last;

  @override
  set last(E last) => throw _writeUnsupported;

  @override
  int get length => resultItems.length;

  @override
  set length(int length) => throw _writeUnsupported;

  @override
  List<E> operator +(List<E> other) => resultItems + other;

  @override
  E operator [](int index) => resultItems[index];

  @override
  void operator []=(int index, E value) => throw _writeUnsupported;

  @override
  void add(E value) => throw _writeUnsupported;

  @override
  void addAll(Iterable<E> iterable) => throw _writeUnsupported;

  @override
  bool any(bool Function(E element) test) => resultItems.any(test);

  @override
  Map<int, E> asMap() => resultItems.asMap();

  @override
  List<R> cast<R>() => resultItems.cast<R>();

  @override
  void clear() => throw _writeUnsupported;

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
  void fillRange(int start, int end, [E fillValue]) => throw _writeUnsupported;

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
  void insert(int index, E element) => throw _writeUnsupported;

  @override
  void insertAll(int index, Iterable<E> iterable) => throw _writeUnsupported;

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
  bool remove(Object value) => throw _writeUnsupported;

  @override
  E removeAt(int index) => throw _writeUnsupported;

  @override
  E removeLast() => throw _writeUnsupported;

  @override
  void removeRange(int start, int end) => throw _writeUnsupported;

  @override
  void removeWhere(bool Function(E element) test) => throw _writeUnsupported;

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) =>
      throw _writeUnsupported;

  @override
  void retainWhere(bool Function(E element) test) => throw _writeUnsupported;

  @override
  Iterable<E> get reversed => resultItems.reversed;

  @override
  void setAll(int index, Iterable<E> iterable) => throw _writeUnsupported;

  @override
  void setRange(int start, int end, Iterable<E> iterable,
          [int skipCount = 0]) =>
      throw _writeUnsupported;

  @override
  void shuffle([Random random]) => throw _writeUnsupported;

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
  void sort([int Function(E a, E b) compare]) => throw _writeUnsupported;

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
