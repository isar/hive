library hive_object_internal;

import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/object/hive_collection_mixin.dart';
import 'package:hive/src/util/delegating_list_view_mixin.dart';
import 'package:meta/meta.dart';

part 'hive_list_impl.dart';

/// Extend `HiveObject` to add useful methods to the objects you want to store
/// in Hive
abstract class HiveObject {
  Box _box;

  dynamic _key;

  // HiveLists in this object
  final _hiveLists = <HiveList>[];

  // HiveLists containing this object
  final _remoteHiveLists = <HiveList, int>{};

  /// Get the box in which this object is stored. Returns `null` if object has
  /// not been added to a box yet.
  Box get box => _box;

  /// Get the key associated with this object. Returns `null` if object has
  /// not been added to a box yet.
  dynamic get key => _key;

  void _requireInitialized() {
    if (_box == null) {
      throw HiveError('This object is currently not in a box.');
    }
  }

  /// Persists this object.
  Future<void> save() {
    _requireInitialized();
    return _box.put(_key, this);
  }

  /// Deletes this object from the box it is stored in.
  Future<void> delete() {
    _requireInitialized();
    return _box.delete(_key);
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

  HiveList<T> backlink<T extends HiveObject>([List<T> objects]) {
    _requireInitialized();
    var hiveList = HiveListImpl<T>(box, objects: objects);
    _hiveLists.add(hiveList);
    return hiveList;
  }

  @protected
  @visibleForTesting
  void init(dynamic key, Box box) {
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

  @protected
  @visibleForTesting
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

  @protected
  @visibleForTesting
  void linkRemoteHiveList(HiveList list) {
    _requireInitialized();
    _remoteHiveLists[list] = (_remoteHiveLists[list] ?? 0) + 1;
  }

  @protected
  @visibleForTesting
  void unlinkRemoteHiveList(HiveListImpl list) {
    var count = _remoteHiveLists[list]--;
    if (count == 0) {
      _remoteHiveLists.remove(list);
    } else {
      _remoteHiveLists[list] = count;
    }
  }
}
