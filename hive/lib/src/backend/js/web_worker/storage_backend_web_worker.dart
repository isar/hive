import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/web_worker/indexed_db_interface.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:meta/meta.dart';

/// Handles all IndexedDB related tasks
class StorageBackendWebWorker extends StorageBackend {
  final DatabaseImplementation _db;

  /// Not part of public API
  StorageBackendWebWorker(this._db);

  @override
  String? get path => null;

  @override
  bool supportsCompaction = false;

  /// Not part of public API
  @visibleForTesting
  ObjectStoreImplementation getStore([String box = 'box']) {
    return ObjectStoreImplementation.fromDatabase(_db, box);
  }

  /// Not part of public API
  @visibleForTesting
  Future<List<dynamic>> getKeys({bool cursor = false}) async {
    final store = getStore();
    var response = await store.getAllKeys();
    return response ?? [];
  }

  /// Not part of public API
  @visibleForTesting
  Future<Iterable<dynamic>> getValues({bool cursor = false}) async {
    var store = getStore();

    var response = await store.getAll();
    return response ?? [];
  }

  @override
  Future<int> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    _db.worker.setRegistry(registry);
    var keys = await getKeys();
    if (!lazy) {
      var i = 0;
      var values = await getValues();
      for (var value in values) {
        var key = keys[i++];
        keystore.insert(Frame(key, value), notify: false);
      }
    } else {
      for (var key in keys) {
        keystore.insert(Frame.lazy(key), notify: false);
      }
    }

    return 0;
  }

  @override
  Future<dynamic> readValue(Frame frame) async {
    return getStore().getObject(frame.key);
  }

  @override
  Future<void> writeFrames(List<Frame> frames) async {
    var store = getStore();
    for (var frame in frames) {
      if (frame.deleted) {
        await store.delete(frame.key);
      } else {
        await store.put(frame.value, frame.key);
      }
    }
  }

  @override
  Future<List<Frame>> compact(Iterable<Frame> frames) {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> clear() {
    return getStore().clear();
  }

  @override
  Future<void> close() {
    _db.close();
    return Future.value();
  }

  @override
  Future<void> deleteFromDisk() {
    final indexDB = context.hasProperty('window')
        ? window.indexedDB
        : WorkerGlobalScope.instance.indexedDB;
    return indexDB!.deleteDatabase(_db.name);
  }

  @override
  Future<void> flush() => Future.value();
}
