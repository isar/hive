part of hive_flutter;

/// Flutter extensions for boxes.
extension BoxX<T> on Box<T> {
  /// Returns a [ValueListenable] which notifies its listeners when an entry
  /// in the box changes.
  ///
  /// If a [key] or [keys] filter is provided, only changes to entries with the
  /// specified keys notify the listeners.
  ValueListenable<Box<T>> listenable({String key, List<String> keys}) =>
      _BoxListenable(this, key, keys);
}

/// Flutter extensions for lazy boxes.
extension LazyBoxX<T> on LazyBox<T> {
  /// Returns a [ValueListenable] which notifies its listeners when an entry
  /// in the box changes.
  ///
  /// If a [key] or [keys] filter is provided, only changes to entries with the
  /// specified keys notify the listeners.
  ValueListenable<LazyBox<T>> listenable({String key, List<String> keys}) =>
      _BoxListenable(this, key, keys);
}

class _BoxListenable<T, B extends BoxBase<T>> extends ValueListenable<B> {
  final B box;

  final String key;

  final List<String> keys;

  final List<VoidCallback> _listeners = [];

  StreamSubscription _subscription;

  _BoxListenable(this.box, this.key, this.keys)
      : assert(key == null || keys == null,
            'You cannot specify both, the key and keys parameters.');

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      if (keys != null) {
        _subscription = box.watch().listen((event) {
          if (keys.contains(event.key)) {
            for (var listener in _listeners) {
              listener();
            }
          }
        });
      } else {
        _subscription = box.watch(key: key).listen((_) {
          for (var listener in _listeners) {
            listener();
          }
        });
      }
    }

    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);

    if (_listeners.isEmpty) {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  @override
  B get value => box;
}
