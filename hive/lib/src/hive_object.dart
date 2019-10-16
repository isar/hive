import 'package:hive/hive.dart';

/// Extend `HiveObject` to add useful methods to the objects you want to store
/// in Hive
abstract class HiveObject {
  Box _box;

  /// Get the box in which this object is stored. Returns `null` if object has
  /// not been added to a box yet.
  Box get box => _box;

  dynamic _key;

  /// Get the key associated with this object. Returns `null` if object has
  /// not been added to a box yet.
  dynamic get key => _key;

  /// Persists this object.
  Future<void> save() {
    if (_box == null) {
      throw HiveError('You have to add this object to a box first '
          'using box.add() or box.put().');
    }
    return _box.put(_key, this);
  }

  /// Deletes this object from the box it is stored in.
  Future<void> delete() {
    if (_box != null) {
      return _box.delete(_key);
    } else {
      return Future.value();
    }
  }

  /// Returns whether this object is currently stored in a box.
  ///
  /// For lazy boxes this only checks if the key exists in the box and NOT
  /// whether this instance is actually stored in the box.
  bool get isInBox {
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
