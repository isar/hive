part of hive;

class HiveObject {
  Box _box;

  Box get box => _box;

  dynamic _key;

  dynamic get key => _key;

  @protected
  void init(Box box, dynamic key) {
    _box = box;
    _key = key;
  }

  Future<void> save() {
    return _box.put(_key, this);
  }

  Future<void> delete() {
    return _box.delete(_key);
  }

  bool get inHive => _box != null;
}
