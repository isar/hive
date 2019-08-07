import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

import 'backend/storage_backend.dart';

class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  final _boxes = HashMap<String, Box>();

  String _homePath;

  HiveImpl() {
    registerInternal(DateTimeAdapter(), 16);
    registerInternal(BigIntAdapter(), 17);
  }

  @override
  String get path {
    if (_homePath == null) {
      throw HiveError('Hive not initialized. Call Hive.init() first.');
    }

    return _homePath;
  }

  @override
  void init(String path) {
    _homePath = path;

    _boxes.clear();
  }

  @override
  Future<CachedBox> box(
    String name, {
    List<int> encryptionKey,
    CompactionStrategy compactionStrategy,
    bool crashRecovery = true,
  }) async {
    var box = await _box(
        name, encryptionKey, compactionStrategy, crashRecovery, false);
    return box as CachedBox;
  }

  @override
  Future<LazyBox> lazyBox(
    String name, {
    List<int> encryptionKey,
    CompactionStrategy compactionStrategy,
    bool crashRecovery = true,
  }) async {
    var box = await _box(
        name, encryptionKey, compactionStrategy, crashRecovery, true);
    return box as LazyBox;
  }

  Future<Box> _box(
    String name,
    List<int> encryptionKey,
    CompactionStrategy compactionStrategy,
    bool crashRecovery,
    bool lazy,
  ) async {
    var existingBox = _boxes[name.toLowerCase()];
    if (existingBox != null) {
      if (existingBox is LazyBox && !lazy) {
        throw HiveError('The box has already been opened as lazy box.');
      } else if (existingBox is CachedBox && lazy) {
        throw HiveError('The box has already been opened as non lazy box.');
      } else {
        return existingBox;
      }
    }

    if (encryptionKey != null) {
      if (encryptionKey.length != 32 ||
          encryptionKey.any((it) => it < 0 || it > 255)) {
        throw ArgumentError(
            'The encryption key has to be a 32 byte (256 bit) array.');
      }
    }

    var options = BoxOptions(
      encryptionKey: encryptionKey,
      compactionStrategy: defaultCompactionStrategy,
    );

    var box = await openBox(this, name.toLowerCase(), lazy, options);
    _boxes[name.toLowerCase()] = box;

    return box;
  }

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name.toLowerCase());
  }

  @override
  Box operator [](String name) {
    return _boxes[name.toLowerCase()];
  }

  @override
  Future close() {
    var closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  void unregisterBox(String name) {
    _boxes.remove(name.toLowerCase());
  }

  @override
  Future deleteFromDisk() {
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
