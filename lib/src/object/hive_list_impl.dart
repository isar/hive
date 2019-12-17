part of hive_object_internal;

class HiveListImpl<E extends HiveObject>
    with HiveCollectionMixin<E>, ListMixin<E>, DelegatingListViewMixin<E>
    implements HiveList<E> {
  final _defaultValue = _DefaultValue();

  final HiveInterface _hive;

  final String boxName;

  final List<dynamic> _keys;

  List<E> _delegate;

  Box _box;

  bool _disposed = false;

  HiveListImpl(Box box, {List<E> objects})
      : _hive = null,
        boxName = box.name,
        _keys = null,
        _box = box,
        _delegate = [] {
    if (objects != null) {
      addAll(objects);
    }
  }

  HiveListImpl.lazy(this.boxName, List<dynamic> keys)
      : _hive = Hive,
        _keys = keys;

  @visibleForTesting
  HiveListImpl.debug(this.boxName, List<dynamic> keys, this._hive)
      : _keys = keys;

  @override
  Box get box {
    if (_box == null) {
      var box = (_hive as HiveImpl).getBoxInternal(boxName);
      if (box == null) {
        throw HiveError(
            'To use this list, you have to open the box "$boxName" first.');
      } else if (box is! Box) {
        throw HiveError('The box "$boxName" is a lazy box. '
            'You can only use HiveLists with normal boxes.');
      } else {
        _box = box as Box;
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
        var element = box.get(key, defaultValue: _defaultValue);
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
      throw HiveError('The HiveObject needs to be in the box "$boxName".');
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
  List<dynamic> get debugKeys => _keys;
}

class _DefaultValue {}
