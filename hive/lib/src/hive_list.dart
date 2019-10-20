part of hive;

class HiveList<E extends HiveObject>
    with HiveCollectionMixin<E>, DelegatingListViewMixin<E> {
  final String _boxName;

  final List<dynamic> _keys;

  Box _box;

  HiveList(Box box)
      : _box = box,
        _boxName = box.name,
        _keys = [];

  HiveList.fromKeys(String boxName, List<dynamic> keys)
      : _boxName = boxName,
        _keys = keys;

  @override
  Box get box {
    if (_box == null) {
      var _box = (Hive as HiveImpl).getBoxInternal(_boxName);
      if (_box == null) {
        throw HiveError(
            'To use this list, you have to open the box "$_boxName" first.');
      }
    }
    return _box;
  }

  @override
  List<E> get delegate {
    var list = <E>[];
    for (var key in _keys) {
      var obj = box.get(key);
      if (obj != null && obj is E) {
        list.add(obj);
      }
    }
    return list;
  }

  void _checkHiveObjectIsValid(E obj) {
    if (obj.box == null || obj.box != box) {
      throw HiveError('The HiveObject needs to be in the box "$_boxName".');
    }
  }

  @override
  void operator []=(int index, E value) {
    _checkHiveObjectIsValid(value);
    _keys[index] = value.key;
  }

  @override
  void add(E value) {
    _checkHiveObjectIsValid(value);
    _keys.add(value.key);
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (var value in iterable) {
      _checkHiveObjectIsValid(value);
    }
    for (var value in iterable) {
      _keys.add(value.key);
    }
  }

  @override
  void clear() {
    _keys.clear();
  }

  @override
  void fillRange(int start, int end, [E fillValue]) {
    _checkHiveObjectIsValid(fillValue);
    _keys.fillRange(start, end, fillValue.key);
  }

  @override
  set first(E value) {
    _checkHiveObjectIsValid(value);
    _keys.first = value.key;
  }

  @override
  void insert(int index, E element) {
    _checkHiveObjectIsValid(element);
    _keys.insert(index, element.key);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    for (var element in iterable) {
      _keys.insert(index++, element);
    }
  }

  @override
  set last(E value) {
    _checkHiveObjectIsValid(value);
    _keys.last = value.key;
  }

  @override
  set length(int newLength) {
    _keys.length;
  }

  @override
  bool remove(Object value) {
    if (value is E) {
      return _keys.remove(value.key);
    } else {
      return false;
    }
  }

  @override
  E removeAt(int index) {
    var key = _keys.removeAt(index);
    return box.get(key) as E;
  }

  @override
  E removeLast() {
    var key = _keys.removeLast();
    return box.get(key) as E;
  }

  @override
  void removeRange(int start, int end) {
    _keys.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _keys.removeWhere((key) => test(box.get(key) as E));
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) {
    _keys.replaceRange(start, end, replacement.map((e) => e.key));
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _keys.retainWhere((key) => test(box.get(key) as E));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    _keys.setAll(index, iterable.map((e) => e.key));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _keys.setRange(start, end, iterable.map((e) => e.key), skipCount);
  }

  @override
  void shuffle([Random random]) {
    _keys.shuffle(random);
  }

  @override
  void sort([int Function(E a, E b) compare]) {
    _keys.sort((a, b) => compare(box.get(a) as E, box.get(b) as E));
  }

  HiveList<T> castHiveList<T extends HiveObject>() {
    return HiveList<T>.fromKeys(_boxName, _keys);
  }
}
