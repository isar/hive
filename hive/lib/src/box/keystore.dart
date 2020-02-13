// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:hive/src/util/indexable_skip_list.dart';
import 'package:meta/meta.dart';

class KeyTransaction<E> {
  final List<dynamic> added = [];
  final Map<dynamic, Frame> deleted = HashMap();

  @visibleForTesting
  KeyTransaction();
}

class Keystore<E> {
  final BoxBase<E> _box;

  final ChangeNotifier _notifier;

  final IndexableSkipList<dynamic, Frame> _store;

  @visibleForTesting
  final ListQueue<KeyTransaction<E>> transactions = ListQueue();

  var _deletedEntries = 0;
  var _autoIncrement = -1;

  Keystore(this._box, this._notifier, KeyComparator keyComparator)
      : _store = IndexableSkipList(keyComparator ?? defaultKeyComparator);

  factory Keystore.debug({
    Iterable<Frame> frames = const [],
    BoxBase<E> box,
    ChangeNotifier notifier,
    KeyComparator keyComparator = defaultKeyComparator,
  }) {
    var keystore =
        Keystore<E>(box, notifier ?? ChangeNotifier(), keyComparator);
    for (var frame in frames) {
      keystore.insert(frame);
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

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool containsKey(dynamic key) {
    return _store.get(key) != null;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  dynamic keyAt(int index) {
    return _store.getKeyAt(index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Frame get(dynamic key) {
    return _store.get(key);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Frame getAt(int index) {
    return _store.getAt(index);
  }

  Iterable<dynamic> getKeys() {
    return _store.keys;
  }

  Iterable<E> getValues() {
    return _store.values.map((e) => e.value as E);
  }

  Iterable<E> getValuesBetween([dynamic startKey, dynamic endKey]) sync* {
    Iterable<Frame> iterable;
    if (startKey != null) {
      iterable = _store.valuesFromKey(startKey);
    } else {
      iterable = _store.values;
    }

    for (var frame in iterable) {
      yield frame.value as E;

      if (frame.key == endKey) break;
    }
  }

  Stream<BoxEvent> watch({dynamic key}) {
    return _notifier.watch(key: key);
  }

  Frame insert(Frame frame, {bool notify = true}) {
    var value = frame.value;
    Frame deletedFrame;

    if (!frame.deleted) {
      var key = frame.key;
      if (key is int && key > _autoIncrement) {
        _autoIncrement = key;
      }

      if (value is HiveObject) {
        value.init(key, _box);
      }

      deletedFrame = _store.insert(key, frame);
    } else {
      deletedFrame = _store.delete(frame.key);
    }

    if (deletedFrame != null) {
      _deletedEntries++;
      if (deletedFrame.value is HiveObject &&
          !identical(deletedFrame.value, value)) {
        (deletedFrame.value as HiveObject).dispose();
      }
    }

    if (notify && (!frame.deleted || deletedFrame != null)) {
      _notifier.notify(frame);
    }

    return deletedFrame;
  }

  bool beginTransaction(List<Frame> newFrames) {
    var transaction = KeyTransaction<E>();
    for (var frame in newFrames) {
      if (!frame.deleted) {
        transaction.added.add(frame.key);
      }

      var deletedFrame = insert(frame);
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
      var deletedFrame = canceled.deleted[key];
      for (var t in transactions) {
        if (t.deleted.containsKey(key)) {
          t.deleted[key] = deletedFrame;
          continue deleted_loop;
        }
        if (t.added.contains(key)) {
          t.deleted[key] = deletedFrame;
          continue deleted_loop;
        }
      }

      _store.insert(key, deletedFrame);
      _notifier.notify(deletedFrame);
    }

    added_loop:
    for (var key in canceled.added) {
      var isOverride = canceled.deleted.containsKey(key);
      for (var t in transactions) {
        if (t.deleted.containsKey(key)) {
          if (!isOverride) {
            t.deleted.remove(key);
          }
          continue added_loop;
        }
        if (t.added.contains(key)) {
          continue added_loop;
        }
      }
      if (!isOverride) {
        _store.delete(key);
        _notifier.notify(Frame.deleted(key));
      }
    }
  }

  int clear() {
    var frameList = frames.toList();

    _store.clear();

    for (var frame in frameList) {
      if (frame.value is HiveObject) {
        // ignore: invalid_use_of_protected_member
        (frame.value as HiveObject).dispose();
      }
      _notifier.notify(Frame.deleted(frame.key));
    }

    _deletedEntries = 0;
    _autoIncrement = -1;
    return frameList.length;
  }

  Future close() {
    return _notifier.close();
  }
}
