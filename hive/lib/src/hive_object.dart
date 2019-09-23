import 'package:hive/hive.dart';

void initHiveObject(dynamic object, Box box, dynamic key) {
  if (object is HiveObject) {
    if (object._box != null) {
      if (object._box != box) {
        throw HiveError('The same instance of an HiveObject cannot '
            'be stored in two different boxes.');
      } else if (object._key != key) {
        throw HiveError('The same instance of an HiveObject cannot '
            'be stored with two different keys.');
      }
    }
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

  bool get isInHive {
    if (_box != null) {
      if (!_box.lazy) {
        return _box.get(key) == this;
      } else {
        return _box.containsKey(key);
      }
    }
    return false;
  }
}
