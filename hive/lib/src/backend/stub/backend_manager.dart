import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';

/// Not part of public API
class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String? path, bool crashRecovery, HiveCipher? cipher) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBox(String name, String? path) {
    throw UnimplementedError();
  }

  @override
  Future<bool> boxExists(String name, String? path) {
    throw UnimplementedError();
  }
}
