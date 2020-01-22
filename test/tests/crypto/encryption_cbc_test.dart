import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/decryption_cbc.dart';
import 'package:hive/src/crypto/encryption_cbc.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:test/test.dart';

import 'message.dart';

void main() {
  group('EncryptionCBC', () {
    test('.generateWorkingKey()', () {
      //expect(AESEngine.generateWorkingKey(key, true), encryptionKey);
      //expect(AESEngine.generateWorkingKey(key, false), decryptionKey);
    });

    test('.processBlock()', () {
      var out = Uint8List(256);
      var cbc = EncryptionCBC()..init(iv);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        cbc.processBlock(encryptionKey, message, i, out, i);
      }
      expect(out, encrypted);
    });
  });

  group('DecryptionCBC', () {
    test('.generateWorkingKey()', () {
      //expect(AESEngine.generateWorkingKey(key, true), encryptionKey);
      //expect(AESEngine.generateWorkingKey(key, false), decryptionKey);
    });

    test('.processBlock()', () {
      var out = Uint8List(256);
      var cbc = DecryptionCBC()..init(iv);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        cbc.processBlock(decryptionKey, encrypted, i, out, i);
      }
      expect(out, message);
    });
  });
}

/*
var e = CBCBlockCipher(AESFastEngine())
          ..init(true, ParametersWithIV(KeyParameter(key), iv));
        e.processBlock(message, i, out, i);
        print(Uint8List.view(out.buffer, i, 16).join(','));
        */

final iv = Uint8List.fromList(List.generate(16, (i) => i * 7));
final encrypted = Uint8List.fromList([
  //
  224, 104, 0, 245, 122, 44, 51, 86, 147, 218, 180, 10, 3, 118, 150, 249,
  212, 122, 103, 97, 182, 98, 12, 197, 53, 229, 100, 242, 74, 177, 50, 81,
  252, 61, 111, 98, 110, 238, 28, 157, 150, 184, 166, 176, 129, 26, 15, 240,
  175, 82, 0, 128, 85, 251, 85, 158, 6, 156, 187, 224, 94, 185, 102, 172,
  46, 70, 15, 220, 48, 114, 196, 247, 6, 230, 218, 47, 245, 138, 207, 244,
  174, 81, 108, 113, 136, 109, 231, 23, 12, 49, 254, 202, 67, 106, 85, 196,
  4, 251, 116, 2, 162, 235, 127, 94, 115, 254, 156, 86, 141, 27, 98, 12,
  119, 178, 95, 255, 190, 66, 181, 130, 96, 180, 106, 128, 197, 189, 149, 176,
  211, 141, 150, 168, 143, 122, 129, 160, 217, 51, 174, 121, 131, 49, 251, 100,
  141, 104, 228, 97, 133, 158, 136, 127, 142, 81, 176, 60, 248, 85, 242, 17,
  79, 69, 174, 61, 120, 44, 108, 251, 55, 95, 59, 232, 95, 149, 1, 171,
  247, 62, 24, 246, 188, 43, 220, 54, 229, 56, 133, 244, 75, 253, 72, 129,
  30, 59, 51, 241, 6, 85, 171, 73, 152, 100, 220, 51, 75, 254, 49, 113,
  43, 97, 115, 253, 121, 174, 162, 113, 24, 112, 115, 51, 149, 203, 80, 195,
  150, 182, 172, 69, 194, 80, 112, 230, 76, 14, 14, 242, 63, 156, 182, 143,
  21, 112, 254, 4, 231, 204, 58, 204, 239, 129, 7, 18, 126, 41, 33, 57,
]);
