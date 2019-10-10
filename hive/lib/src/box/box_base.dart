import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

abstract class BoxBase implements Box {
  @override
  final String name;

  @visibleForTesting
  final HiveImpl hive;

  final CompactionStrategy _compactionStrategy;

  @protected
  final StorageBackend backend;

  @protected
  @visibleForTesting
  Keystore keystore;

  bool _open = true;

  BoxBase(
    this.hive,
    this.name,
    KeyComparator keyComparator,
    this._compactionStrategy,
    this.backend,
  ) {
    keystore = Keystore(this, ChangeNotifier(), keyComparator);
  }

  @override
  bool get isOpen => _open;

  @override
  String get path => backend.path;

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
    return keystore.getAt(index).key;
  }

  Future<void> initialize() {
    return backend.initialize(hive, keystore);
  }

  @override
  bool containsKey(dynamic key) {
    checkOpen();
    return keystore.containsKey(key);
  }

  @override
  Future<void> put(dynamic key, dynamic value) => putAll({key: value});

  @override
  Future<void> delete(dynamic key) => deleteAll([key]);

  @override
  Future<int> add(dynamic value) async {
    var key = keystore.autoIncrement();
    await put(key, value);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<dynamic> values) async {
    var entries = <int, dynamic>{};
    for (var value in values) {
      entries[keystore.autoIncrement()] = value;
    }
    await putAll(entries);
    return entries.keys;
  }

  @override
  Future<void> putAt(int index, dynamic value) {
    return putAll({keystore.getAt(index).key: value});
  }

  @override
  Future<void> deleteAt(int index) {
    return deleteAll([keystore.getAt(index).key]);
  }

  @override
  Future<int> clear() async {
    checkOpen();

    await backend.clear();
    return keystore.clear();
  }

  @override
  Future<void> compact() async {
    checkOpen();

    if (!backend.supportsCompaction) return;
    if (keystore.deletedEntries == 0) return;

    await backend.compact(keystore.frames);
    keystore.resetDeletedEntries();
  }

  @protected
  Future<void> performCompactionIfNeeded() {
    if (_compactionStrategy(keystore.length, keystore.deletedEntries)) {
      return compact();
    }

    return Future.value();
  }

  @override
  Future<void> close() async {
    if (!_open) return;

    await keystore.close();

    _open = false;
    hive.unregisterBox(name);
    await backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    await keystore.close();

    _open = false;
    hive.unregisterBox(name);
    await backend.deleteFromDisk();
  }
}
