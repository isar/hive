import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/crypto/padded_cipher.dart';

class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String path, bool crashRecovery, PaddedCipher cipher) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBox(String name, String path) {
    throw UnimplementedError();
  }
}
