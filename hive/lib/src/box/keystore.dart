import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class _KeyTransaction {
  final List<dynamic> added = [];
  final Map<dynamic, BoxEntry> deleted = {};
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
  final Map<dynamic, BoxEntry> entries;

  @visibleForTesting
  final ListQueue<_KeyTransaction> transactions = ListQueue();

  var _deletedEntries = 0;
  var _autoIncrement = -1;

  Keystore({KeyComparator keyComparator, Map<dynamic, BoxEntry> entries})
      : entries = SplayTreeMap.of(entries ?? {}, keyComparator ?? _compareKeys);

  int get deletedEntries => _deletedEntries;

  int get length => entries.length;

  int autoIncrement() {
    return ++_autoIncrement;
  }

  void updateAutoIncrement(int key) {
    if (key > _autoIncrement) {
      _autoIncrement = key;
    }
  }

  bool containsKey(dynamic key) {
    return entries.containsKey(key);
  }

  dynamic keyAt(int index) {
    var keys = entries.keys;
    var keyIndex = 0;
    for (var key in keys) {
      if (index == keyIndex) return key;
      keyIndex++;
    }
    return null;
  }

  BoxEntry get(dynamic key) {
    return entries[key];
  }

  Iterable<dynamic> getKeys() {
    return entries.keys;
  }

  Iterable<dynamic> getValues() {
    return entries.values.map((e) => e.value);
  }

  Map<dynamic, dynamic> toValueMap() {
    var map = <dynamic, dynamic>{};
    for (var key in entries.keys) {
      map[key] = entries[key].value;
    }
    return map;
  }

  void addAll(Map<dynamic, BoxEntry> newEntries, [int deletedEntries = 0]) {
    _deletedEntries += deletedEntries;
    for (var key in newEntries.keys) {
      var entry = newEntries[key];
      entries[key] = entry;
      if (key is int && key > _autoIncrement) {
        _autoIncrement = key;
      }
    }
  }

  void deleteAll(List<dynamic> keys) {
    for (var key in keys) {
      if (entries.remove(key) != null) {
        _deletedEntries++;
      }
    }
  }

  void beginAddTransaction(Map<dynamic, BoxEntry> newEntries) {
    var transaction = _KeyTransaction();
    for (var key in newEntries.keys) {
      var deletedEntry = entries.remove(key);
      if (deletedEntry != null) {
        transaction.deleted[key] = deletedEntry;
        _deletedEntries++;
      }

      transaction.added.add(key);
      entries[key] = newEntries[key];
      if (key is int && key > _autoIncrement) {
        _autoIncrement = key;
      }
    }
    transactions.add(transaction);
  }

  void beginDeleteTransaction(Iterable<dynamic> keys) {
    var transaction = _KeyTransaction();
    for (var key in keys) {
      var deletedEntry = entries.remove(key);
      if (deletedEntry != null) {
        transaction.deleted[key] = deletedEntry;
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
        entries[key] = canceled.deleted[key];
      } else if (shouldDelete) {
        entries.remove(key);
      }
    }
  }

  Map<dynamic, BoxEntry> clear() {
    var oldEntries = Map.of(entries);
    entries.clear();
    _deletedEntries = 0;
    transactions.clear();
    return oldEntries;
  }
}

class BoxEntry {
  final dynamic value;
  int offset;
  int length;

  BoxEntry(this.value, [this.offset, this.length]);

  @override
  bool operator ==(dynamic other) {
    if (other is BoxEntry) {
      return other.value == value &&
          other.offset == offset &&
          other.length == length;
    }
    return false;
  }
}
