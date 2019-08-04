import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/box_transaction_mixin.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

abstract class BoxBase extends TypeRegistryImpl
    with BoxTransactionMixin
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
  int deletedEntries = 0;

  bool _open = true;

  BoxBase(this.hive, this.name, this.options, this.backend)
      : notifier = ChangeNotifier(),
        keystore = Keystore(),
        super(hive);

  BoxBase.debug(this.hive, this.name, this.options, this.backend, this.keystore,
      [ChangeNotifier notifier])
      : notifier = notifier ?? ChangeNotifier(),
        super(hive);

  @override
  bool get isOpen => _open;

  @override
  String get path => backend.path;

  @override
  Iterable<String> get keys {
    checkOpen();
    return keystore.getAll().keys;
  }

  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError('Box has already been closed.');
    }
  }

  @override
  Stream<BoxEvent> watch({String key}) {
    checkOpen();
    return notifier.watch(key: key);
  }

  Future initialize() async {
    deletedEntries = await backend.initialize(
        keystore.entries, options.lazy, options.crashRecovery);
  }

  @override
  bool has(String key) {
    checkOpen();
    return keystore.containsKey(key);
  }

  @override
  Future delete(String key) {
    return put(key, null);
  }

  @override
  Future deleteAll(Iterable<String> keysToDelete) {
    var nullValues = List.filled(keysToDelete.length, null);
    return putAll(Map<String, void>.fromIterables(keysToDelete, nullValues));
  }

  @override
  Future<int> clear() async {
    checkOpen();

    await backend.clear();
    var oldEntries = keystore.entries;
    keystore.clear();
    deletedEntries = 0;

    for (var key in oldEntries.keys) {
      notifier.notify(key, null);
    }

    return oldEntries.length;
  }

  @override
  Future<void> compact() async {
    checkOpen();
    if (deletedEntries == 0) return;
    var newEntries = await backend.compact(keystore.entries);
    keystore.clear(newEntries);
    deletedEntries = 0;
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
