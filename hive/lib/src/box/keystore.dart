import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/hive_object.dart';
import 'package:hive/src/util/indexable_skip_list.dart';
import 'package:meta/meta.dart';

class KeyTransaction {
  final List<dynamic> added = [];
  final Map<dynamic, Frame> deleted = HashMap();

  @visibleForTesting
  KeyTransaction();
}

int _compareKeys(dynamic k1, dynamic k2) {
  if (k1.runtimeType == k2.runtimeType) {
    return (k1 as Comparable).compareTo(k2);
  } else {
    return k1 is int ? -1 : 1;
  }
}

class Keystore {
  final Box _box;

  final IndexableSkipList<dynamic, Frame> _store;

  @visibleForTesting
  final ListQueue<KeyTransaction> transactions = ListQueue();

  var _deletedEntries = 0;
  var _autoIncrement = -1;

  Keystore(this._box, [KeyComparator keyComparator])
      : _store = IndexableSkipList(keyComparator ?? _compareKeys);

  factory Keystore.debug(Iterable<Frame> frames,
      [Box box, KeyComparator keyComparator]) {
    var keystore = Keystore(box, keyComparator);
    for (var frame in frames) {
      keystore.add(frame);
    }
    return keystore;
  }

  int get deletedEntries => _deletedEntries;

  int get length => _store.length;

  Iterable<Frame> get frames => _store.values;

  void resetDeletedEntries() {
    _deletedEntries = 0;
  }

  int autoIncrement() {
    return ++_autoIncrement;
  }

  void updateAutoIncrement(int key) {
    if (key > _autoIncrement) {
      _autoIncrement = key;
    }
  }

  bool containsKey(dynamic key) {
    return _store.get(key) != null;
  }

  dynamic keyAt(int index) {
    return _store.getKeyAt(index);
  }

  Frame get(dynamic key) {
    return _store.get(key);
  }

  Frame getAt(int index) {
    return _store.getAt(index);
  }

  Iterable<dynamic> getKeys() {
    return _store.keys;
  }

  Iterable<dynamic> getValues() {
    return _store.values.map((e) => e.value);
  }

  Frame add(Frame frame) {
    var key = frame.key;
    if (key is int && key > _autoIncrement) {
      _autoIncrement = key;
    }

    if (frame.value is HiveObject) {
      initHiveObject(key, frame.value as HiveObject, _box);
    }

    var deletedFrame = _store.insert(key, frame);
    if (deletedFrame != null) {
      _deletedEntries++;
      if (deletedFrame.value is HiveObject) {
        unloadHiveObject(deletedFrame.value as HiveObject);
      }
    }
    return deletedFrame;
  }

  Frame delete(Frame key) {
    var deletedFrame = _store.delete(key);
    if (deletedFrame != null) {
      _deletedEntries++;
      if (deletedFrame.value is HiveObject) {
        unloadHiveObject(deletedFrame.value as HiveObject);
      }
    }
    return deletedFrame;
  }

  bool beginTransaction(List<Frame> newFrames) {
    var transaction = KeyTransaction();
    for (var frame in newFrames) {
      Frame deletedFrame;
      if (frame.deleted) {
        deletedFrame = delete(frame.key);
      } else {
        deletedFrame = add(frame);
        transaction.added.add(frame.key);
      }
      if (deletedFrame != null) {
        transaction.deleted[frame.key] = deletedFrame;
      }
    }

    if (transaction.added.isNotEmpty || transaction.deleted.isNotEmpty) {
      transactions.add(transaction);
      return true;
    } else {
      return false;
    }
  }

  void commitTransaction() {
    transactions.removeFirst();
  }

  void cancelTransaction() {
    var canceled = transactions.removeFirst();

    deleted_loop:
    for (var key in canceled.deleted.keys) {
      for (var t in transactions) {
        if (t.deleted.containsKey(key)) {
          t.deleted[key] = canceled.deleted[key];
          continue deleted_loop;
        }
        if (t.added.contains(key)) {
          t.deleted[key] = canceled.deleted[key];
          continue deleted_loop;
        }
      }
      _store.insert(key, canceled.deleted[key]);
    }

    added_loop:
    for (var key in canceled.added) {
      for (var t in transactions) {
        if (t.deleted.containsKey(key)) {
          if (!canceled.deleted.containsKey(key)) {
            t.deleted.remove(key);
          }
          continue added_loop;
        }
        if (t.added.contains(key)) {
          continue added_loop;
        }
      }
      if (!canceled.deleted.containsKey(key)) {
        _store.delete(key);
      }
    }
  }

  void clear() {
    for (var frame in frames) {
      if (frame.value is HiveObject) {
        unloadHiveObject(frame.value as HiveObject);
      }
    }
    _store.clear();
    _deletedEntries = 0;
  }
}
