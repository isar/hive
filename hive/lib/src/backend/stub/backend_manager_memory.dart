import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';

/// Not part of public API
class BackendManagerMemory implements BackendManagerInterface {
  static final Map<String?, Map<String, StorageBackend>> _backends = {};

  @override
  Future<StorageBackend> open(String name, String? path, bool crashRecovery,
      HiveCipher? cipher, String? collection) async {
    final backend = StorageBackendMemory(null, cipher);
    _backends[collection] ??= {};
    _backends[collection]![name] = backend;
    return backend;
  }

  @override
  Future<Map<String, StorageBackend>> openCollection(
      Set<String> names,
      String? path,
      bool crashRecovery,
      HiveCipher? cipher,
      String? collection) async {
    return Map.fromEntries(await Future.wait(names.map((e) =>
        open(e, path, crashRecovery, cipher, collection)
            .then((value) => MapEntry(e, value)))));
  }

  @override
  Future<void> deleteBox(String name, String? path, String? collection) async {
    _backends[collection]?.remove(name);
  }

  @override
  Future<bool> boxExists(String name, String? path, String? collection) async {
    return _backends[collection]?.containsKey(name) ?? false;
  }
}
