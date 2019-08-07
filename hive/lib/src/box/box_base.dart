import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/box_transaction_mixin.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

abstract class BoxBase<T extends Box> extends TypeRegistryImpl
    with BoxTransactionMixin<T>
    implements Box {
  @override
  final String name;

  @protected
  final HiveImpl hive;

  @protected
  final BoxOptions options;

  @protected
  final StorageBackend backend;

  @protected
  final ChangeNotifier notifier;

  @protected
  final Keystore keystore;

  @protected
  @visibleForTesting
  int deletedEntries = 0;

  bool _open = true;

  int _autoIncrement = -1;

  BoxBase(
    this.hive,
    this.name,
    this.options,
    this.backend, [
    Keystore keystore,
    ChangeNotifier notifier,
  ])  : keystore = keystore ?? Keystore(),
        notifier = notifier ?? ChangeNotifier(),
        super(hive);

  @override
  bool get isOpen => _open;

  @override
  String get path => backend.path;

  @override
  Iterable<dynamic> get keys {
    checkOpen();
    return keystore.getKeys();
  }

  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError('Box has already been closed.');
    }
  }

  @override
  int autoIncrement() {
    return ++_autoIncrement;
  }

  @protected
  void updateAutoIncrement(int key) {
    if (key > _autoIncrement) {
      _autoIncrement = key;
    }
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    checkOpen();
    return notifier.watch(key: key);
  }

  Future initialize() async {
    var entries = <String, BoxEntry>{};
    deletedEntries =
        await backend.initialize(entries, lazy, options.crashRecovery);
    keystore.addAll(entries);
  }

  @override
  bool containsKey(dynamic key) {
    checkOpen();
    return keystore.containsKey(key);
  }

  @override
  Future delete(dynamic key) {
    return put(key, null);
  }

  @override
  Future deleteAll(Iterable<dynamic> keysToDelete) {
    var map = <dynamic, void>{};
    for (var key in keysToDelete) {
      map[key] = null;
    }
    return putAll(map);
  }

  @override
  Future<int> clear() async {
    checkOpen();

    await backend.clear();
    var oldEntries = keystore.clear();
    deletedEntries = 0;

    for (var key in oldEntries.keys) {
      notifier.notify(key, null);
    }

    return oldEntries.length;
  }

  @override
  Future<void> compact() async {
    /*checkOpen();
    if (deletedEntries == 0) return;
    var entries = keystore.getAll();
    var newEntries = await backend.compact(entries);
    keystore.clear(newEntries);
    deletedEntries = 0;*/
  }

  @protected
  Future<void> performCompactionIfNeeded() {
    /*if (options.compactionStrategy(_entries.length, deletedEntries)) {
      return compact();
    }*/

    return Future.value();
  }

  @override
  Future<void> close() async {
    if (!_open) return;

    await waitForRunningTransactions();
    await notifier.close();

    _open = false;
    hive.unregisterBox(name);
    await backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    await waitForRunningTransactions();
    await notifier.close();

    _open = false;
    hive.unregisterBox(name);
    await backend.deleteFromDisk();
  }
}
