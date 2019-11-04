part of hive_object_internal;

class HiveListImpl<E extends HiveObject>
    with HiveCollectionMixin<E>, ListMixin<E>, DelegatingListViewMixin<E>
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
        _delegate = objects ?? [] {
    for (var element in _delegate) {
      element.linkRemoteHiveList(this);
    }
  }

  HiveListImpl.lazy(String boxName, List<dynamic> keys)
      : _getBox = (Hive as HiveImpl).getBoxInternal,
        _boxName = boxName,
        _keys = keys;

  @visibleForTesting
  HiveListImpl.debug(String boxName, List<dynamic> keys, HiveImpl hive)
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
    if (_delegate == null) {
      var list = <E>[];
      for (var key in _keys) {
        var element = box.get(key);
        if (element != null) {
          list.add(element as E);
        }
      }
      _delegate = list;
    }

    return _delegate;
  }

  void notifyRemoveObject(HiveObject object) {
    var retained = <E>[];
    for (var obj in delegate) {
      if (obj != object) {
        retained.add(obj);
      }
    }
    _delegate = retained;
  }

  @override
  void dispose() {
    for (var element in delegate) {
      element.unlinkRemoteHiveList(this);
    }
    _keys = null;
    _delegate = null;
  }

  void _checkHiveObjectIsValid(E obj) {
    if (obj == null) {
      throw HiveError('HiveLists must not contain null elements.');
    } else if (obj.box != box) {
      throw HiveError('The HiveObject needs to be in the box "$_boxName".');
    }
  }

  @override
  set length(int newLength) {
    if (newLength < delegate.length) {
      for (var i = newLength; i < delegate.length; i++) {
        delegate[i].unlinkRemoteHiveList(this);
      }
    }
    delegate.length = newLength;
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
  void add(E element) {
    _checkHiveObjectIsValid(element);
    element.linkRemoteHiveList(this);
    delegate.add(element);
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

  @visibleForTesting
  String get debugBoxName => _boxName;

  @visibleForTesting
  List<dynamic> get debugKeys => _keys;
}
