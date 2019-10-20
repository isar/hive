import 'dart:math';

abstract class UnmodifiableResultsMixin<E> implements List<E> {
  @override
  void operator []=(int index, E value) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot change the length of HiveResults');
  }

  @override
  set first(E element) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  set last(E element) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  void setAll(int at, Iterable<E> iterable) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  void add(E value) {
    throw UnsupportedError('Cannot change add to HiveResults');
  }

  @override
  void insert(int index, E element) {
    throw UnsupportedError('Cannot change add to HiveResults');
  }

  @override
  void insertAll(int at, Iterable<E> iterable) {
    throw UnsupportedError('Cannot change add to HiveResults');
  }

  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError('Cannot change add to HiveResults');
  }

  @override
  bool remove(Object element) {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  void removeWhere(bool test(E element)) {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  void retainWhere(bool test(E element)) {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  void sort([Comparator<E> compare]) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  void shuffle([Random random]) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  void clear() {
    throw UnsupportedError('Cannot clear HiveResults');
  }

  @override
  E removeAt(int index) {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  E removeLast() {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnsupportedError('Cannot modify HiveResults');
  }

  @override
  void removeRange(int start, int end) {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw UnsupportedError('Cannot change remove from HiveResults');
  }

  @override
  void fillRange(int start, int end, [E fillValue]) {
    throw UnsupportedError('Cannot modify HiveResults');
  }
}
