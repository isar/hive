import 'dart:collection';

import 'package:hive/hive.dart';

class ListView<E> extends ListBase<E> {
  final Box box;

  ListView(this.box);

  @override
  int get length => box.length;

  @override
  set length(int length) => throw UnsupportedError('message');

  @override
  E operator [](int index) => box.getAt(index) as E;

  @override
  void operator []=(int index, value) => box.putAt(index, value);

  @override
  void add(E element) => box.add(element);

  @override
  void addAll(Iterable<E> iterable) => box.addAll(iterable);

  @override
  void clear() => box.clear();
}
