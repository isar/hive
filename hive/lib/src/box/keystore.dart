import 'dart:collection';

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
  final Map<dynamic, BoxEntry> entries;
  final ListQueue<_KeyTransaction> _transactions = ListQueue();
  var _deletedEntries = 0;

  Keystore([Map<dynamic, BoxEntry> entries])
      : entries = SplayTreeMap.from(entries ?? {}, _compareKeys);

  int get deletedEntries => _deletedEntries;

  bool containsKey(dynamic key) {
    return entries.containsKey(key);
  }

  BoxEntry get(dynamic key) {
    return entries[key];
  }

  Iterable<dynamic> getKeys() {
    return entries.keys;
  }

  Iterable<BoxEntry> getValues() {
    return entries.values;
  }

  Map<dynamic, dynamic> toMap() {
    var map = <dynamic, dynamic>{};
    for (var key in entries.keys) {
      map[key] = entries[key].value;
    }
    return map;
  }

  void addAll(Map<dynamic, BoxEntry> newEntries) {
    for (var key in newEntries.keys) {
      var entry = newEntries[key];
      if (entry != null) {
        entries[key] = entry;
      } else {
        entries.remove(key);
        _deletedEntries++;
      }
    }
  }

  void keyTransaction(Map<dynamic, BoxEntry> newEntries) {
    var transaction = _KeyTransaction();
    for (var key in newEntries.keys) {
      var entry = newEntries[key];
      if (entry == null || entries.containsKey(key)) {
        transaction.deleted[key] = entries[key];
        entries.remove(key);
        _deletedEntries++;
      }
      if (entry != null) {
        transaction.added.add(key);
        entries[key] = entry;
      }
    }
    _transactions.add(transaction);
  }

  void commitKeyTransaction() {
    _transactions.removeFirst();
  }

  void cancelKeyTransaction() {
    var transaction = _transactions.removeFirst();
    for (var key in transaction.added) {
      var shouldRemove = true;
      for (var t in _transactions) {
        if (t.added.contains(key)) {
          shouldRemove = false;
          break;
        }
      }
      if (shouldRemove) {
        entries.remove(key);
      }
    }

    for (var key in transaction.deleted.keys) {
      var shouldAdd = true;
      for (var t in _transactions) {
        if (t.added.contains(key)) {
          shouldAdd = false;
          t.deleted[key] = transaction.deleted[key];
          break;
        }
      }
      if (shouldAdd) {
        entries[key] = transaction.deleted[key];
      }
    }
  }

  Map<String, BoxEntry> clear([Map<String, BoxEntry> newEntries]) {
    var oldEntries = _transactions.first.entries;
    _transactions.clear();
    _transactions.add(KeyTransaction._(
        SplayTreeMap.from(newEntries) ?? SplayTreeMap(), null, null));
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
