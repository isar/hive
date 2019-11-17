import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/crypto_helper.dart';

class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String path, bool crashRecovery, CryptoHelper crypto) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBox(String name, String path) {
    throw UnimplementedError();
  }
}
