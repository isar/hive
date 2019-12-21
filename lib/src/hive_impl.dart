import 'dart:collection';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/backend/storage_backend_memory.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

import 'backend/storage_backend.dart';

class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  final _boxes = HashMap<String, BoxBaseImpl>();
  final BackendManager _manager;

  @visibleForTesting
  String homePath;

  HiveImpl() : _manager = BackendManager() {
    _registerDefaultAdapters();
  }

  HiveImpl.debug(this._manager) {
    _registerDefaultAdapters();
  }

  void _registerDefaultAdapters() {
    registerInternal(DateTimeAdapter(), 16);
    registerInternal(BigIntAdapter(), 17);
  }

  @override
  void init(String path) {
    homePath = path;

    _boxes.clear();
  }

  @visibleForTesting
  CryptoHelper getCryptoHelper(List<int> encryptionKey) {
    if (encryptionKey == null) return null;
    if (encryptionKey.length != 32 ||
        encryptionKey.any((it) => it < 0 || it > 255)) {
      throw ArgumentError(
          'The encryption key has to be a 32 byte (256 bit) array.');
    }
    return CryptoHelper(Uint8List.fromList(encryptionKey));
  }

  Future<BoxBase<E>> _openBox<E>(
    String name,
    bool lazy,
    List<int> key,
    KeyComparator comparator,
    CompactionStrategy compaction,
    bool recovery,
    String path,
    Uint8List bytes,
  ) async {
    assert(comparator != null);
    assert(compaction != null);
    assert(path == null || bytes == null);
    name = name.toLowerCase();
    if (isBoxOpen(name)) {
      if (lazy) {
        return lazyBox(name);
      } else {
        return box(name);
      }
    } else {
      var crypto = getCryptoHelper(key);
      var boxPath = path ?? homePath;

      StorageBackend backend;
      if (bytes != null) {
        backend = StorageBackendMemory(Uint8List.fromList(bytes), crypto);
      } else {
        backend = await _manager.open(name, boxPath, recovery, crypto);
      }

      BoxBaseImpl<E> box;
      if (lazy) {
        box = LazyBoxImpl<E>(this, name, comparator, compaction, backend);
      } else {
        box = BoxImpl<E>(this, name, comparator, compaction, backend);
      }

      await box.initialize();
      _boxes[name] = box;

      return box;
    }
  }

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    List<int> encryptionKey,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String path,
    Uint8List bytes,
  }) async {
    return await _openBox<E>(name, false, encryptionKey, keyComparator,
        compactionStrategy, crashRecovery, path, bytes) as Box<E>;
  }

  @override
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    List<int> encryptionKey,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String path,
  }) async {
    return await _openBox<E>(name, true, encryptionKey, keyComparator,
        compactionStrategy, crashRecovery, path, null) as LazyBox<E>;
  }

  BoxBase<E> getBoxInternal<E>(String name, [bool lazy]) {
    var lowerCaseName = name.toLowerCase();
    var box = _boxes[lowerCaseName];
    if (box != null) {
      if ((lazy == null || box.lazy == lazy) && box.valueType == E) {
        return box as BoxBase<E>;
      } else {
        var typeName = box is LazyBox
            ? 'LazyBox<${box.valueType}>'
            : 'Box<${box.valueType}>';
        throw HiveError('The box "$lowerCaseName" is already open '
            'and of type $typeName.');
      }
    } else {
      throw HiveError('Box not found. Did you forget to call Hive.openBox()?');
    }
  }

  BoxBase getBoxWithoutCheckInternal(String name) {
    var lowerCaseName = name.toLowerCase();
    return _boxes[lowerCaseName];
  }

  @override
  Box<E> box<E>(String name) => getBoxInternal<E>(name, false) as Box<E>;

  @override
  LazyBox<E> lazyBox<E>(String name) =>
      getBoxInternal<E>(name, true) as LazyBox<E>;

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name.toLowerCase());
  }

  @override
  Future<void> close() {
    var closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  void unregisterBox(String name) {
    _boxes.remove(name.toLowerCase());
  }

  @override
  Future<void> deleteBoxFromDisk(String name, {String path}) async {
    var box = _boxes[name.toLowerCase()];
    if (box != null) {
      await box.deleteFromDisk();
    } else {
      await _manager.deleteBox(name, path ?? homePath);
    }
  }

  @override
  Future<void> deleteFromDisk() {
    var deleteFutures = _boxes.values.toList().map((box) {
      return box.deleteFromDisk();
    });

    return Future.wait(deleteFutures);
  }

  @override
  List<int> generateSecureKey() {
    var secureRandom = CryptoHelper.createSecureRandom();
    return secureRandom.nextBytes(32);
  }
}
