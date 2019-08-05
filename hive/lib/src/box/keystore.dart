import 'dart:collection';

class Keystore {
  final List<KeyTransaction> _transactions;

  Keystore([Map<String, BoxEntry> entries])
      : _transactions = [KeyTransaction._(entries ?? HashMap(), null, null)];

  bool containsKey(String key) {
    return get(key) != null;
  }

  BoxEntry get(String key) {
    for (var i = _transactions.length - 1; i >= 0; i--) {
      if (_transactions[i].entries.containsKey(key)) {
        return _transactions[i].entries[key];
      }
    }
    return null;
  }

  Map<String, BoxEntry> getAll() {
    var entries = HashMap<String, BoxEntry>();
    for (var i = 0; i < _transactions.length; i++) {
      var trxEntries = _transactions[i].entries;
      for (var key in trxEntries.keys) {
        var value = trxEntries[key];
        if (value != null) {
          entries[key] = value;
        } else {
          entries.remove(key);
        }
      }
    }
    return entries;
  }

  void addAll(Map<String, BoxEntry> entries) {
    _transactions.first.entries.addAll(entries);
  }

  KeyTransaction keyTransaction(Map<String, BoxEntry> entries) {
    var transaction =
        KeyTransaction._(entries, _transactions.first, _transactions);
    _transactions.add(transaction);
    return transaction;
  }

  Map<String, BoxEntry> clear([Map<String, BoxEntry> newEntries]) {
    var oldEntries = _transactions.first.entries;
    _transactions.clear();
    _transactions.add(KeyTransaction._(newEntries ?? {}, null, null));
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

class KeyTransaction {
  final Map<String, BoxEntry> entries;
  final KeyTransaction _root;
  final List<KeyTransaction> _transactions;
  int deletedEntries;

  KeyTransaction._(this.entries, this._root, this._transactions);

  void commit() {
    _root.entries.addAll(entries);
    _transactions.remove(this);
  }

  Map<String, BoxEntry> cancel() {
    _transactions.remove(this);
    return entries;
  }
}
