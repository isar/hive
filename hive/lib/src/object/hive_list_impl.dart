part of hive_object_internal;

class HiveListImpl<E extends HiveObject>
    with HiveCollectionMixin<E>, DelegatingListViewMixin<E>
    implements HiveList<E> {
  final Box Function(String) _getBox;

  final String _boxName;

  List<dynamic> _keys;

  List<E> _delegate;

  Box _box;

  HiveListImpl(Box box, {List<E> objects})
      : _getBox = null,
        _boxName = box.name,
        _box = box,
        _delegate = objects ?? [];

  HiveListImpl.lazy(String boxName, List<dynamic> keys)
      : _getBox = (Hive as HiveImpl).getBoxInternal,
        _boxName = boxName,
        _keys = keys;

  @visibleForTesting
  HiveListImpl.debug(String boxName, List<dynamic> keys, HiveImpl hive)
      : _getBox = hive.getBoxInternal,
        _boxName = boxName,
        _keys = keys;

  void notifyRemoveObject(HiveObject object) {
    if (_delegate != null) {
      var retained = <E>[];
      for (var obj in _delegate) {
        if (obj != object) {
          retained.add(obj);
        }
      }
      _delegate = retained;
    } else {
      var retained = <dynamic>[];
      for (var key in _keys) {
        if (key != object.key) {
          retained.add(key);
        }
      }
      _keys = retained;
    }
  }

  @override
  void dispose() {
    for (var element in this) {
      element._remoteHiveLists.remove(this);
    }
  }

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
    if (_delegate == null) {
      var list = <E>[];
      for (var key in _keys) {
        list.add(box.get(key) as E);
      }
      _delegate = list;
    }

    return _delegate;
  }

  void _checkHiveObjectIsValid(E obj) {
    if (obj.box != box) {
      throw HiveError('The HiveObject needs to be in the box "$_boxName".');
    }
  }

  @override
  void operator []=(int index, E value) {
    _checkHiveObjectIsValid(value);
    value.linkRemoteHiveList(this);

    var oldValue = delegate[index];
    delegate[index] = value;

    oldValue.unlinkRemoteHiveList(this);
  }

  @override
  void add(E value) {
    _checkHiveObjectIsValid(value);
    value.linkRemoteHiveList(this);
    delegate.add(value);
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    for (var element in iterable) {
      element.linkRemoteHiveList(this);
    }
    delegate.addAll(iterable);
  }

  @override
  void clear() {
    for (var element in delegate) {
      element.unlinkRemoteHiveList(this);
    }
  }

  @override
  void fillRange(int start, int end, [E fillValue]) {
    _checkHiveObjectIsValid(fillValue);
    for (var i = start; i < end; i++) {
      delegate[i].unlinkRemoteHiveList(this);
      fillValue.linkRemoteHiveList(this);
    }
    _keys.fillRange(start, end, fillValue.key);
  }

  @override
  set first(E value) {
    _checkHiveObjectIsValid(value);
    delegate.first.unlinkRemoteHiveList(this);
    value.linkRemoteHiveList(this);
    delegate.first = value;
  }

  @override
  void insert(int index, E element) {
    _checkHiveObjectIsValid(element);
    element.linkRemoteHiveList(this);
    delegate.insert(index, element);
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    for (var element in iterable) {
      element.linkRemoteHiveList(this);
    }
    delegate.insertAll(index, iterable);
  }

  @override
  set last(E value) {
    _checkHiveObjectIsValid(value);
    delegate.last.unlinkRemoteHiveList(this);
    value.linkRemoteHiveList(this);
    delegate.last = value;
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('You cannot change the length of a HiveList.');
  }

  @override
  bool remove(Object value) {
    if (value is E) {
      _checkHiveObjectIsValid(value);
      if (delegate.remove(value)) {
        value.unlinkRemoteHiveList(this);
        return true;
      }
    }
    return false;
  }

  @override
  E removeAt(int index) {
    var element = delegate.removeAt(index);
    element.unlinkRemoteHiveList(this);
    return element;
  }

  @override
  E removeLast() {
    var element = delegate.removeLast();
    element.unlinkRemoteHiveList(this);
    return element;
  }

  @override
  void removeRange(int start, int end) {
    for (var i = start; i < end; i++) {
      delegate[i].unlinkRemoteHiveList(this);
    }
    delegate.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    delegate.removeWhere((element) {
      if (test(element)) {
        element.unlinkRemoteHiveList(this);
        return true;
      }
      return false;
    });
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) {
    for (var element in replacement) {
      _checkHiveObjectIsValid(element);
    }
    _keys.replaceRange(start, end, replacement.map<dynamic>((e) => e.key));
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _keys.retainWhere((key) => test(box.get(key) as E));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    _keys.setAll(index, iterable.map((e) => e.key));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    for (var element in iterable) {
      _checkHiveObjectIsValid(element);
    }
    _keys.setRange(start, end, iterable.map((e) => e.key), skipCount);
  }

  @override
  void shuffle([Random random]) {
    delegate.shuffle(random);
  }

  @override
  void sort([int Function(E a, E b) compare]) {
    delegate.sort(compare);
  }

  @visibleForTesting
  String get debugBoxName => _boxName;

  @visibleForTesting
  List<dynamic> get debugKeys => _keys;
}
