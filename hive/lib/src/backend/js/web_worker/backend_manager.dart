import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/web_worker/storage_backend_web_worker.dart';
import 'package:hive/src/backend/storage_backend.dart';

import 'indexed_db_interface.dart';

/// Opens IndexedDB databases
class BackendManager implements BackendManagerInterface {
  IndexedDbWebWorkerInterface? indexedDB;

  @override
  Future<StorageBackend> open(
      String name, String? path, bool crashRecovery, HiveCipher? cipher) async {
    indexedDB = IndexedDbWebWorkerInterface(cipher);
    var db = await indexedDB!.open(name);
    return StorageBackendWebWorker(db);
  }

  @override
  Future<void> deleteBox(String name, String? path) {
    return indexedDB!.deleteDatabase(name);
  }

  @override
  Future<bool> boxExists(String name, String? path) async {
    // https://stackoverflow.com/a/17473952
    try {
      var _exists = true;
      await indexedDB!.open(name);
      return _exists;
    } catch (error) {
      return false;
    }
  }
}
