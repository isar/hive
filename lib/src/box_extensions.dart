part of hive_flutter;

extension BoxX<T> on Box<T> {
  /// Returns a [ValueListenable] which notifies its listeners when an entry
  /// in the box changes.
  ///
  /// If a [key] is provided, only changes to entries with the specified key
  /// notify the listeners.
  ValueListenable<Box<T>> listenable({String key}) =>
      _HiveListenable(this, key);
}

extension LazyBoxX<T> on LazyBox<T> {
  /// Returns a [ValueListenable] which notifies its listeners when an entry
  /// in the box changes.
  ///
  /// If a [key] is provided, only changes to entries with the specified key
  /// notify the listeners.
  ValueListenable<LazyBox<T>> listenable({String key}) =>
      _HiveListenable(this, key);
}

class _HiveListenable<T, B extends BoxBase<T>> extends ValueListenable<B> {
  final B box;

  final String key;

  final List<VoidCallback> _listeners = [];

  StreamSubscription _subscription;

  _HiveListenable(this.box, this.key);

  @override
  void addListener(VoidCallback listener) {
    if (_listeners.isEmpty) {
      _subscription = box.watch(key: key).listen((_) {
        for (var listener in _listeners) {
          listener();
        }
      });
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
