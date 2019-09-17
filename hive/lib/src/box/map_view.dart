import 'dart:collection';
import 'package:hive/hive.dart';

class MapView<E> extends MapBase<dynamic, E> {
  final Box _box;

  MapView(this._box);

  @override
  E operator [](dynamic key) => _box.get(key) as E;

  @override
  void operator []=(dynamic key, E value) {
    _box.put(key, value);
  }

  @override
  void clear() => _box.clear();

  @override
  bool containsKey(dynamic key) => _box.containsKey(key);

  @override
  int get length => _box.length;

  @override
  bool get isEmpty => _box.isEmpty;

  @override
  bool get isNotEmpty => _box.isNotEmpty;

  @override
  Iterable<dynamic> get keys => _box.keys;

  @override
  Iterable<E> get values => _box.values.cast<E>();

  @override
  E remove(dynamic key) {
    var value = _box.get(key);
    _box.delete(key);
    return value as E;
  }
}
