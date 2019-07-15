class BoxOptions {
  final List<int> encryptionKey;
  final bool cached;

  BoxOptions({
    this.encryptionKey,
    this.cached = true,
  }) {
    if (encryptionKey != null) {
      if (encryptionKey.length != 32 ||
          encryptionKey.any((it) => it < 0 || it > 255)) {
        throw ArgumentError(
            'The encryption key has to be a 32 byte (256 bit) array.');
      }
    }
  }

  bool get encrypted => encryptionKey != null;
}