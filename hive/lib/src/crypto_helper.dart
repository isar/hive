import 'dart:math';
import 'dart:typed_data';

import 'package:hive/src/util/crc32.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/random/fortuna_random.dart';

typedef Crypto = Uint8List Function(Uint8List bytes);

class CryptoHelper {
  final Uint8List keyBytes;
  final int keyCrc;
  final BlockCipher cipher;
  final SecureRandom random;

  CryptoHelper(this.keyBytes)
      : keyCrc = Crc32.compute(Digest('SHA-256').process(keyBytes)),
        cipher = PaddedBlockCipher('AES/CBC/PKCS7'),
        random = createSecureRandom();

  static SecureRandom createSecureRandom() {
    var secureRandom = FortunaRandom();
    var random = Random.secure();
    var seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = random.nextInt(255);
    }
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }

  Crypto get encryptor => (Uint8List bytes) {
        var iv = random.nextBytes(16);
        var params = PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(keyBytes), iv),
          null,
        );

        cipher.reset();
        cipher.init(true, params);

        var encrypted = cipher.process(bytes);
        return Uint8List.fromList([...iv, ...encrypted]);
      };

  Crypto get decryptor => (Uint8List bytes) {
        var iv = Uint8List.view(bytes.buffer, bytes.offsetInBytes, 16);
        var params = PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(keyBytes), iv),
          null,
        );

        cipher.reset();
        cipher.init(false, params);

        var encryptedBytes = Uint8List.view(
          bytes.buffer,
          bytes.offsetInBytes + 16,
          bytes.length - 16,
        );
        return cipher.process(encryptedBytes);
      };
}
