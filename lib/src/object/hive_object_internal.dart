part of hive_object_internal;

extension HiveObjectInternal on HiveObject {
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
