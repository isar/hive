import 'dart:collection';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/adapters/uint8_list_adapter.dart';
import 'package:hive/src/box_impl.dart';
import 'package:hive/src/box_options.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

class HiveInstanceImpl extends TypeRegistryImpl implements HiveInstance {
  final _boxes = HashMap<String, Box>();

  String _homePath;

  @override
  String get path {
    if (_homePath == null) {
      throw HiveError("Hive not initialized. Call Hive.init() first.");
    }

    return _homePath;
  }

  @override
  void init(String path) {
    _homePath = path;

    _boxes.clear();

    resetAdapters();
    registerInternal(Uint8ListAdapter(), 16);
    registerInternal(DateTimeAdapter(), 17);
  }

  @override
  Future<Box> box(
    String name, {
    List<int> encryptionKey,
    int version = 1,
    Migrator migrator,
    truncateOnCorruption = false,
  }) async {
    var existingBox = _boxes[name];
    if (existingBox != null) return existingBox;

    await Directory(_homePath).create(recursive: true);

    var options = BoxOptions(
      encryptionKey: encryptionKey,
      version: version,
      migrator: migrator,
      truncateOnCorruption: truncateOnCorruption,
    );

    var box = await BoxImpl.open(this, name, options);
    _boxes[name] = box;

    return box;
  }

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name);
  }

  @override
  Future close({bool compact = false}) {
    var closeFutures = _boxes.values.map((box) {
      return box.close(compact: compact);
    });

    return Future.wait(closeFutures);
  }

  void unregisterBox(String name) {
    _boxes.remove(name);
  }

  @override
  Future deleteFromDisk() {
    var deleteFutures = _boxes.values.map((box) {
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
