import 'dart:html';
import 'dart:indexed_db';

import 'package:hive/src/backend/js/storage_backend.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/crypto_helper.dart';

class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String path, bool crashRecovery, CryptoHelper crypto) async {
    var db =
        await window.indexedDB.open(name, version: 1, onUpgradeNeeded: (e) {
      var db = e.target.result as Database;
      if (!db.objectStoreNames.contains('box')) {
        db.createObjectStore('box');
      }
    });

    return StorageBackendJs(db, crypto);
  }

  @override
  Future<void> deleteBox(String name, String path) {
    return window.indexedDB.deleteDatabase(name);
  }
}
