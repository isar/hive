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

class Keystore {
  final List<KeyTransaction> _transactions;

  Keystore([Map<String, BoxEntry> entries])
      : _transactions = [KeyTransaction._(entries ?? {}, null, null)];

  Map<String, BoxEntry> get entries => _transactions.first.entries;

  bool containsKey(String key) {
    for (var i = _transactions.length - 1; i >= 0; i--) {
      if (_transactions[i].entries.containsKey(key)) {
        return _transactions[i].entries[key] != null;
      }
    }
    return false;
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
    var entries = <String, BoxEntry>{};
    for (var i = 0; i < _transactions.length; i++) {
      entries.addAll(_transactions[i].entries);
    }
    entries.removeWhere((k, v) => v == null);
    return entries;
  }

  KeyTransaction keyTransaction(Map<String, BoxEntry> entries) {
    var transaction =
        KeyTransaction._(entries, _transactions.first, _transactions);
    _transactions.add(transaction);
    return transaction;
  }

  void clear([Map<String, BoxEntry> newEntries]) {
    _transactions.clear();
    _transactions.add(KeyTransaction._(newEntries ?? {}, null, null));
  }
}
