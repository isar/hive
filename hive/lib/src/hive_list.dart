part of hive;

class HiveList<E extends HiveObject>
    with HiveCollectionMixin<E>, DelegatingListViewMixin<E> {
  final Box Function(String) _getBox;

  final String _boxName;

  List<dynamic> _keys;

  Box _box;

  HiveList(Box box, {List<dynamic> keys})
      : _getBox = null,
        _boxName = box.name,
        _box = box,
        _keys = keys ?? [];

  HiveList.internal(String boxName, List<dynamic> keys)
      : _getBox = (Hive as HiveImpl).getBoxInternal,
        _boxName = boxName,
        _keys = keys;

  @visibleForTesting
  HiveList.debug(String boxName, List<dynamic> keys, HiveImpl hive)
      : _getBox = hive.getBoxInternal,
        _boxName = boxName,
        _keys = keys;

  @override
  Box get box {
    if (_box == null) {
      _box = _getBox(_boxName);
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

  void _refreshKeys() {
    var newKeys = <dynamic>[];
    for (var key in _keys) {
      if (box.containsKey(key)) {
        newKeys.add(key);
      }
    }
    _keys = newKeys;
  }

  void _checkHiveObjectIsValid(E obj) {
    if (obj.box != box) {
      throw HiveError('The HiveObject needs to be in the box "$_boxName".');
    }
  }

  @override
  void operator []=(int index, E value) {
    _checkHiveObjectIsValid(value);
    _refreshKeys();
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
    _refreshKeys();
    _keys.fillRange(start, end, fillValue.key);
  }

  @override
  set first(E value) {
    _checkHiveObjectIsValid(value);
    _refreshKeys();
    _keys.first = value.key;
  }

  @override
  void insert(int index, E element) {
    _checkHiveObjectIsValid(element);
    _refreshKeys();
    _keys.insert(index, element.key);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    _refreshKeys();
    for (var element in iterable) {
      _keys.insert(index++, element);
    }
  }

  @override
  set last(E value) {
    _checkHiveObjectIsValid(value);
    _refreshKeys();
    _keys.last = value.key;
  }

  @override
  set length(int newLength) {
    _keys.length = newLength;
  }

  @override
  bool remove(Object value) {
    if (value is E) {
      _checkHiveObjectIsValid(value);
      return _keys.remove(value.key);
    } else {
      return false;
    }
  }

  @override
  E removeAt(int index) {
    _refreshKeys();
    var key = _keys.removeAt(index);
    return box.get(key) as E;
  }

  @override
  E removeLast() {
    _refreshKeys();
    var key = _keys.removeLast();
    return box.get(key) as E;
  }

  @override
  void removeRange(int start, int end) {
    _refreshKeys();
    _keys.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _refreshKeys();
    _keys.removeWhere((key) => test(box.get(key) as E));
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) {
    for (var element in replacement) {
      _checkHiveObjectIsValid(element);
    }
    _refreshKeys();
    _keys.replaceRange(start, end, replacement.map<dynamic>((e) => e.key));
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _refreshKeys();
    _keys.retainWhere((key) => test(box.get(key) as E));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    _refreshKeys();
    _keys.setAll(index, iterable.map((e) => e.key));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    _refreshKeys();
    _keys.setRange(start, end, iterable.map((e) => e.key), skipCount);
  }

  @override
  void shuffle([Random random]) {
    _keys.shuffle(random);
  }

  @override
  void sort([int Function(E a, E b) compare]) {
    _refreshKeys();
    _keys.sort((a, b) => compare(box.get(a) as E, box.get(b) as E));
  }

  HiveList<T> castHiveList<T extends HiveObject>() {
    return HiveList<T>.internal(_boxName, _keys);
  }

  @visibleForTesting
  String get debugBoxName => _boxName;

  @visibleForTesting
  List<dynamic> get debugKeys => _keys;
}
