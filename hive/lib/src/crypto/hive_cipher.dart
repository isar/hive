part of hive;

/// Abstract cipher can be implemented to customize encryption.
///
/// Encryption and decryption can be either synchronous (e.g. with the
/// [HiveAesCipher] implementation) or asynchronous for use with
/// hardware-accelerated crypto implementations.
abstract class HiveCipher {
  /// Calculate a hash of the key. Make sure to use a secure hash.
  int calculateKeyCrc();

  /// The maximum size the input can have after it has been encrypted.
  int maxEncryptedSize(Uint8List inp);

  ///
  /// - [inp]: the total bytes in plain text
  /// - [inpOff]: the byte offset to start encryption at
  /// - [inpLength]: the number of bytes (length) to encrypt
  /// - [out]: the buffer to write the encrypted output in
  /// - [outOff]: the byte offset to write the encrypted output to
  ///
  /// returns the length of the new encrypted output
  FutureOr<int> encrypt(
      Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff);

  /// Decrypt the given bytes.
  ///
  /// - [inp]: the total encrypted bytes
  /// - [inpOff]: the byte offset to start decryption at
  /// - [inpLength]: the number of bytes (length) to decrypt
  /// - [out]: the buffer to write the decrypted output in
  /// - [outOff]: the byte offset to write the decrypted output to
  ///
  /// returns the length of the new decrypted output
  FutureOr<int> decrypt(
      Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff);
}
