part of hive_object_internal;

extension HiveObjectInternal on HiveObject {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void init(dynamic key, BoxBase box) {
    if (_box != null) {
      if (_box != box) {
        throw HiveError('The same instance of an HiveObject cannot '
            'be stored in two different boxes.');
      } else if (_key != key) {
        throw HiveError('The same instance of an HiveObject cannot '
            'be stored with two different keys ("$_key" and "$key").');
      }
    }
    _box = box;
    _key = key;
  }

  void dispose() {
    for (var list in _hiveLists.keys) {
      (list as HiveListImpl).invalidate();
    }

    _hiveLists.clear();

    _box = null;
    _key = null;
  }

  void linkHiveList(HiveList list) {
    _requireInitialized();
    _hiveLists[list] = (_hiveLists[list] ?? 0) + 1;
  }

  void unlinkHiveList(HiveList list) {
    if (--_hiveLists[list] <= 0) {
      _hiveLists.remove(list);
    }
  }

  bool isInHiveList(HiveList list) {
    return _hiveLists.containsKey(list);
  }

  @visibleForTesting
  Map<HiveList, int> get debugHiveLists => _hiveLists;
}
