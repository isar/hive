import 'dart:html';
import 'dart:indexed_db';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/storage_backend_js.dart';
import 'package:hive/src/backend/storage_backend.dart';

/// Opens IndexedDB databases
class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String? path, bool crashRecovery, HiveCipher? cipher) async {
    var db =
        await window.indexedDB!.open(name, version: 1, onUpgradeNeeded: (e) {
      var db = e.target.result as Database;
      if (!db.objectStoreNames!.contains('box')) {
        db.createObjectStore('box');
      }
    });

    return StorageBackendJs(db, cipher);
  }

  @override
  Future<void> deleteBox(String name, String? path) {
    return window.indexedDB!.deleteDatabase(name);
  }

  @override
  Future<bool> boxExists(String name, String? path) async {
    // https://stackoverflow.com/a/17473952
    try {
      var _exists = true;
      await window.indexedDB!.open(name, version: 1, onUpgradeNeeded: (e) {
        e.target.transaction!.abort();
        _exists = false;
      });
      return _exists;
    } catch (error) {
      return false;
    }
  }
}
