import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/util/indexable_skip_list.dart';
import 'package:meta/meta.dart';

class _KeyTransaction {
  final List<dynamic> added = [];
  final Map<dynamic, Frame> deleted = {};
}

int _compareKeys(dynamic k1, dynamic k2) {
  if (k1.runtimeType == k2.runtimeType) {
    return (k1 as Comparable).compareTo(k2);
  } else {
    return k1 is int ? -1 : 1;
  }
}

class Keystore {
  @visibleForTesting
  final IndexableSkipList<dynamic, Frame> frames;

  @visibleForTesting
  final ListQueue<_KeyTransaction> transactions = ListQueue();

  var _deletedEntries = 0;
  var _autoIncrement = -1;

  Keystore([KeyComparator keyComparator])
      : frames = IndexableSkipList(keyComparator ?? _compareKeys);

  factory Keystore.debug(Iterable<Frame> frames,
      [KeyComparator keyComparator]) {
    var keystore = Keystore(keyComparator);
    for (var frame in frames) {
      keystore.add(frame);
    }
    return keystore;
  }

  int get deletedEntries => _deletedEntries;

  int get length => frames.length;

  int autoIncrement() {
    return ++_autoIncrement;
  }

  void updateAutoIncrement(int key) {
    if (key > _autoIncrement) {
      _autoIncrement = key;
    }
  }

  bool containsKey(dynamic key) {
    return frames.containsKey(key);
  }

  dynamic keyAt(int index) {
    var keys = frames.keys;
    var keyIndex = 0;
    for (var key in keys) {
      if (index == keyIndex) return key;
      keyIndex++;
    }
    return null;
  }

  Frame get(dynamic key) {
    return frames[key];
  }

  Iterable<dynamic> getKeys() {
    return frames.keys;
  }

  Iterable<dynamic> getValues() {
    return frames.values.map((e) => e.value);
  }

  Map<dynamic, dynamic> toValueMap() {
    var map = <dynamic, dynamic>{};
    for (var frame in frames.values) {
      map[frame.key] = frame.value;
    }
    return map;
  }

  void add(Frame frame) {
    var key = frame.key;
    if (frames.containsKey(key)) {
      _deletedEntries++;
    }
    if (key is int && key > _autoIncrement) {
      _autoIncrement = key;
    }
    frames[key] = frame;
  }

  void delete(dynamic key) {
    if (frames.remove(key) != null) {
      _deletedEntries++;
    }
  }

  void beginAddTransaction(List<Frame> newFrames) {
    var transaction = _KeyTransaction();
    for (var frame in newFrames) {
      var key = frame.key;
      var deletedFrame = frames.remove(key);
      if (deletedFrame != null) {
        transaction.deleted[key] = deletedFrame;
        _deletedEntries++;
      }

      transaction.added.add(key);
      frames[key] = frame;
      if (key is int && key > _autoIncrement) {
        _autoIncrement = key;
      }
    }
    transactions.add(transaction);
  }

  void beginDeleteTransaction(Iterable<dynamic> keys) {
    var transaction = _KeyTransaction();
    for (var key in keys) {
      var deletedFrame = frames.remove(key);
      if (deletedFrame != null) {
        transaction.deleted[key] = deletedFrame;
        _deletedEntries++;
      }
    }
    transactions.add(transaction);
  }

  void commitTransaction() {
    transactions.removeFirst();
  }

  void cancelTransaction() {
    var canceled = transactions.removeFirst();
    var keys = Set.of(canceled.added);
    keys.addAll(canceled.deleted.keys);

    for (var key in keys) {
      var shouldAdd = canceled.deleted.containsKey(key);
      var shouldDelete = canceled.added.contains(key);
      for (var t in transactions) {
        if (t.added.contains(key) || t.deleted.containsKey(key)) {
          if (canceled.deleted.containsKey(key)) {
            t.deleted[key] = canceled.deleted[key];
          } else {
            t.deleted.remove(key);
          }
          break;
        }
      }

      for (var t in transactions) {
        if (t.added.contains(key)) {
          shouldAdd = false;
          shouldDelete = false;
        } else if (t.deleted.containsKey(key)) {
          shouldAdd = false;
        }
      }

      if (shouldAdd) {
        frames[key] = canceled.deleted[key];
      } else if (shouldDelete) {
        frames.remove(key);
      }
    }
  }

  Iterable<Frame> clear() {
    var oldEntries = frames.values.toList();
    frames.clear();
    _deletedEntries = 0;
    transactions.clear();
    return oldEntries;
  }
}
