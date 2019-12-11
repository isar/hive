part of hive_object_internal;

extension HiveObjectInternal on HiveObject {
  void init(dynamic key, BoxBase box) {
    if (_box != null) {
      if (_box != box) {
        throw HiveError('The same instance of an HiveObject cannot '
            'be stored in two different boxes.');
      } else if (_key != key) {
        throw HiveError('The same instance of an HiveObject cannot '
            'be stored with two different keys.');
      }
    }
    _box = box;
    _key = key;
  }

  void unload() {
    for (var list in _remoteHiveLists.keys) {
      (list as HiveListImpl).notifyRemoveObject(this);
    }
    for (var list in _hiveLists) {
      list.dispose();
    }
    _box = null;
    _key = null;
  }

  void linkRemoteHiveList(HiveList list) {
    _requireInitialized();
    _remoteHiveLists[list] = (_remoteHiveLists[list] ?? 0) + 1;
  }

  void unlinkRemoteHiveList(HiveListImpl list) {
    if (--_remoteHiveLists[list] == 0) {
      _remoteHiveLists.remove(list);
    }
  }

  Map<HiveList, int> get debugRemoteHiveLists => _remoteHiveLists;
}
