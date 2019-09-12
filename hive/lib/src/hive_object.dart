import 'package:hive/hive.dart';

void initHiveObject(dynamic object, Box box, dynamic key) {
  if (object is HiveObject) {
    object._box = box;
    object._key = key;
  }
}

class HiveObject {
  Box _box;

  Box get box => _box;

  dynamic _key;

  dynamic get key => _key;

  Future<void> save() {
    return _box.put(_key, this);
  }

  Future<void> delete() {
    return _box.delete(_key);
  }

  bool get inHive => _box.containsKey(key);
}
