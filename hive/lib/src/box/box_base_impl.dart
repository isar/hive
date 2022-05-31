import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

/// Not part of public API
abstract class BoxBaseImpl<E> implements BoxBase<E> {
  static BoxBase<E> nullImpl<E>() => _NullBoxBase<E>();

  @override
  final String name;

  /// Not part of public API
  @visibleForTesting
  final HiveImpl hive;

  final CompactionStrategy _compactionStrategy;

  /// Not part of public API
  @protected
  final StorageBackend backend;

  /// Not part of public API
  ///
  /// Not `late final` for testing
  @protected
  @visibleForTesting
  late Keystore<E> keystore;

  bool _open = true;

  /// Not part of public API
  BoxBaseImpl(
    this.hive,
    this.name,
    KeyComparator? keyComparator,
    this._compactionStrategy,
    this.backend,
  ) {
    keystore = Keystore(this, ChangeNotifier(), keyComparator);
  }

  /// Not part of public API
  Type get valueType => E;

  @override
  bool get isOpen => _open;

  @override
  String? get path => backend.path;

  @override
  Iterable<dynamic> get keys {
    checkOpen();
    return keystore.getKeys();
  }

  @override
  int get length {
    checkOpen();
    return keystore.length;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  /// Not part of public API
  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError('Box has already been closed.');
    }
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    checkOpen();
    return keystore.watch(key: key);
  }

  @override
  dynamic keyAt(int index) {
    checkOpen();
    return keystore.getAt(index)!.key;
  }

  /// Not part of public API
  Future<void> initialize() {
    return backend.initialize(hive, keystore, lazy);
  }

  @override
  bool containsKey(dynamic key) {
    checkOpen();
    return keystore.containsKey(key);
  }

  @override
  Future<void> put(
    dynamic key,
    E value, {
    bool notify = true,
  }) =>
      putAll(
        {key: value},
        notify: notify,
      );

  @override
  Future<void> delete(
    dynamic key, {
    bool notify = true,
  }) =>
      deleteAll(
        [key],
        notify: notify,
      );

  @override
  Future<int> add(
    E value, {
    bool notify = true,
  }) async {
    var key = keystore.autoIncrement();
    await put(key, value, notify: notify);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(
    Iterable<E> values, {
    bool notify = true,
  }) async {
    var entries = <int, E>{};
    for (var value in values) {
      entries[keystore.autoIncrement()] = value;
    }
    await putAll(entries, notify: notify);
    return entries.keys;
  }

  @override
  Future<void> putAt(
    int index,
    E value, {
    bool notify = true,
  }) {
    return putAll({keystore.getAt(index)!.key: value}, notify: notify);
  }

  @override
  Future<void> deleteAt(
    int index, {
    bool notify = true,
  }) {
    return delete(keystore.getAt(index)!.key, notify: notify);
  }

  @override
  Future<int> clear({bool notify = true}) async {
    checkOpen();

    await backend.clear();
    return keystore.clear(notify: notify);
  }

  @override
  Future<void> compact() async {
    checkOpen();

    if (!backend.supportsCompaction) return;
    if (keystore.deletedEntries == 0) return;

    await flush();

    await backend.compact(keystore.frames);
    keystore.resetDeletedEntries();
  }

  /// Not part of public API
  @protected
  FutureOr<void> performCompactionIfNeeded() {
    if (_compactionStrategy(keystore.length, keystore.deletedEntries)) {
      return compact();
    }
  }

  @override
  Future<void> close() async {
    if (!_open) return;

    try {
      await flush();
    } finally {
      _open = false;
    }

    await keystore.close();
    hive.unregisterBox(name);

    await backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    if (_open) {
      // deleteFromDisk does not work in some cases
      await clear();
      _open = false;
      await keystore.close();
      hive.unregisterBox(name);
    }

    await backend.deleteFromDisk();
  }
}

class _NullBoxBase<E> implements BoxBase<E> {
  @override
  Never add(
    E value, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never addAll(
    Iterable<E> values, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never clear({bool notify = true}) => throw UnimplementedError();

  @override
  Never close() => throw UnimplementedError();

  @override
  Never compact() => throw UnimplementedError();

  @override
  Never containsKey(key) => throw UnimplementedError();

  @override
  Never delete(
    key, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never deleteAll(
    Iterable keys, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never deleteAt(
    int index, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never deleteFromDisk() => throw UnimplementedError();

  @override
  Never get isEmpty => throw UnimplementedError();

  @override
  Never get isNotEmpty => throw UnimplementedError();

  @override
  Never get isOpen => throw UnimplementedError();

  @override
  Never keyAt(int index) => throw UnimplementedError();

  @override
  Never get keys => throw UnimplementedError();

  @override
  Never get lazy => throw UnimplementedError();

  @override
  Never get length => throw UnimplementedError();

  @override
  Never get name => throw UnimplementedError();

  @override
  Never get path => throw UnimplementedError();

  @override
  Never put(
    key,
    E value, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never putAll(
    Map<dynamic, E> entries, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never putAt(
    int index,
    E value, {
    bool notify = true,
  }) =>
      throw UnimplementedError();

  @override
  Never watch({key}) => throw UnimplementedError();

  @override
  Never flush() => throw UnimplementedError();
}
