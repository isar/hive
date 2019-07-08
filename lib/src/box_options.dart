import 'package:hive/hive.dart';

class BoxOptions {
  final List<int> encryptionKey;
  final int version;
  final Migrator migrator;
  final bool truncateOnCorruption;

  BoxOptions({
    this.encryptionKey,
    this.version = 1,
    this.migrator,
    this.truncateOnCorruption,
  }) {
    if (encryptionKey != null) {
      if (encryptionKey.length != 32 ||
          encryptionKey.any((it) => it < 0 || it > 255)) {
        throw ArgumentError(
            "The encryption key has to be a 32 byte (256 bit) array.");
      }
    }

    if (version < 0) {
      throw ArgumentError("Data version has to be positive");
    }
  }

  bool get encrypted => encryptionKey != null;
}
