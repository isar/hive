import 'dart:math';

abstract class IterableListDelegate<E> implements List<E> {
  Iterable<E> get listSource;

  @override
  E get first => this[0];

  @override
  E get last => this[length - 1];

  @override
  List<E> operator +(List<E> other) => listSource.followedBy(other).toList();

  @override
  bool any(bool Function(E element) test) => listSource.any(test);

  @override
  Map<int, E> asMap() {
    var map = <int, E>{};
    var i = 0;
    for (var element in listSource) {
      map[i++] = element;
    }
    return map;
  }

  @override
  List<R> cast<R>() => listSource.cast<R>().toList();

  @override
  bool contains(Object element) => listSource.contains(element);

  @override
  E elementAt(int index) => this[index];

  @override
  bool every(bool Function(E element) test) => listSource.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) f) =>
      listSource.expand(f);

  @override
  E firstWhere(bool Function(E element) test, {E Function() orElse}) =>
      listSource.firstWhere(test);

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      listSource.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => listSource.followedBy(other);

  @override
  void forEach(void Function(E element) f) => listSource.forEach(f);

  @override
  Iterable<E> getRange(int start, int end) {
    var iterable = skip(start);
    return iterable.take(end - start);
  }

  @override
  int indexOf(E element, [int start = 0]) {
    // TODO: implement indexOf
    return null;
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) {
    // TODO: implement indexWhere
    return null;
  }

  @override
  void insert(int index, E element) {
    // TODO: implement insert
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    // TODO: implement insertAll
  }

  @override
  // TODO: implement isEmpty
  bool get isEmpty => null;

  @override
  // TODO: implement isNotEmpty
  bool get isNotEmpty => null;

  @override
  // TODO: implement iterator
  Iterator<E> get iterator => null;

  @override
  String join([String separator = ""]) {
    // TODO: implement join
    return null;
  }

  @override
  int lastIndexOf(E element, [int start]) {
    // TODO: implement lastIndexOf
    return null;
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int start]) {
    // TODO: implement lastIndexWhere
    return null;
  }

  @override
  E lastWhere(bool Function(E element) test, {E Function() orElse}) {
    // TODO: implement lastWhere
    return null;
  }

  @override
  Iterable<T> map<T>(T Function(E e) f) {
    // TODO: implement map
    return null;
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    // TODO: implement reduce
    return null;
  }

  @override
  bool remove(Object value) {
    // TODO: implement remove
    return null;
  }

  @override
  E removeAt(int index) {
    // TODO: implement removeAt
    return null;
  }

  @override
  E removeLast() {
    // TODO: implement removeLast
    return null;
  }

  @override
  void removeRange(int start, int end) {
    // TODO: implement removeRange
  }

  @override
  void removeWhere(bool Function(E element) test) {
    // TODO: implement removeWhere
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) {
    // TODO: implement replaceRange
  }

  @override
  void retainWhere(bool Function(E element) test) {
    // TODO: implement retainWhere
  }

  @override
  // TODO: implement reversed
  Iterable<E> get reversed => null;

  @override
  void setAll(int index, Iterable<E> iterable) {
    // TODO: implement setAll
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    // TODO: implement setRange
  }

  @override
  void shuffle([Random random]) {
    // TODO: implement shuffle
  }

  @override
  // TODO: implement single
  E get single => null;

  @override
  E singleWhere(bool Function(E element) test, {E Function() orElse}) {
    // TODO: implement singleWhere
    return null;
  }

  @override
  Iterable<E> skip(int count) {
    // TODO: implement skip
    return null;
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) {
    // TODO: implement skipWhile
    return null;
  }

  @override
  void sort([int Function(E a, E b) compare]) {
    // TODO: implement sort
  }

  @override
  List<E> sublist(int start, [int end]) {
    // TODO: implement sublist
    return null;
  }

  @override
  Iterable<E> take(int count) {
    // TODO: implement take
    return null;
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    // TODO: implement takeWhile
    return null;
  }

  @override
  List<E> toList({bool growable = true}) {
    // TODO: implement toList
    return null;
  }

  @override
  Set<E> toSet() {
    // TODO: implement toSet
    return null;
  }

  @override
  Iterable<E> where(bool Function(E element) test) {
    // TODO: implement where
    return null;
  }

  @override
  Iterable<T> whereType<T>() {
    // TODO: implement whereType
    return null;
  }
}
