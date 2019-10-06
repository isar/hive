import 'package:hive/hive.dart';

class HiveObject {
  Box _box;

  Box get box => _box;

  dynamic _key;

  dynamic get key => _key;

  Future<void> save() {
    if (_box == null) {
      throw HiveError('You have to add this object to a box first '
          'using box.add() or box.put().');
    }
    return _box.put(_key, this);
  }

  Future<void> delete() {
    if (_box != null) {
      return _box.delete(_key);
    } else {
      return Future.value();
    }
  }

  bool get isInHive {
    if (_box != null) {
      if (_box.lazy) {
        return _box.containsKey(_key);
      } else {
        return true;
      }
    }
    return false;
  }
}

void initHiveObject(dynamic key, HiveObject object, Box box) {
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

void unloadHiveObject(HiveObject object) {
  object._box = null;
  object._key = null;
}
