import 'package:hive/src/util/iterable_list_delegate.dart';
import 'package:hive/hive.dart';

class ListView<E> extends IterableListDelegate<E> {
  Box box;

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
  void add(E value) => box.add(value);

  @override
  void addAll(Iterable<E> iterable) => box.addAll(iterable);

  @override
  void clear() => box.clear();

  @override
  void fillRange(int start, int end, [E fillValue]) {
    for (var i = start; i < length; i++) {
      box.putAt(i, fillValue);
    }
  }

  @override
  set first(E value) => box.putAt(0, value);

  @override
  set last(E value) => box.putAt(box.length - 1, value);

  @override
  Iterable<E> get listSource => box.values.cast<E>();
}
