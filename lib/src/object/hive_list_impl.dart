part of hive_object_internal;

class HiveListImpl<E extends HiveObject>
    with HiveCollectionMixin<E>, ListMixin<E>, DelegatingListViewMixin<E>
    implements HiveList<E> {
  final _defaultValue = _DefaultValue();

  final BoxBase Function(String) _getBox;

  final String _boxName;

  final List<dynamic> _keys;

  List<E> _delegate;

  BoxBase _box;

  bool _disposed = false;

  HiveListImpl(BoxBase box, {List<E> objects})
      : _getBox = null,
        _boxName = box.name,
        _keys = null,
        _box = box,
        _delegate = [] {
    if (objects != null) {
      addAll(objects);
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
  BoxBase get box {
    if (_box == null) {
      _box = _getBox(_boxName);
      if (_box == null) {
        throw HiveError('To use this list, you have to open the '
            'box "${_boxName ?? _box.name}" first.');
      }
    }
    return _box;
  }

  @override
  List<E> get delegate {
    if (_delegate == null) {
      if (_disposed) {
        throw HiveError('This HiveList has already been disposed.');
      }

      var list = <E>[];
      for (var key in _keys) {
        dynamic element;
        if (box is Box) {
          element = (box as Box).get(key, defaultValue: _defaultValue);
        } else {
          element = (box as LazyBox).get(key, defaultValue: _defaultValue);
        }
        if (element != _defaultValue) {
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
    _delegate = null;
    _disposed = true;
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

class _DefaultValue {}
