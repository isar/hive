import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:test/test.dart';

import 'message.dart';

void main() {
  group('AESEngine', () {
    test('.generateWorkingKey()', () {
      expect(AESEngine.generateWorkingKey(key, true), encryptionKey);
      expect(AESEngine.generateWorkingKey(key, false), decryptionKey);
    });

    test('.encryptBlock()', () {
      var out = Uint8List(256);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        AESEngine.encryptBlock(encryptionKey, message, i, out, i);
      }
      expect(out, encrypted);
    });

    test('.decryptBlock()', () {
      var out = Uint8List(256);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        AESEngine.decryptBlock(decryptionKey, encrypted, i, out, i);
      }
      expect(out, message);
    });
  });
}

final encrypted = Uint8List.fromList([
  //
  90, 110, 4, 87, 8, 251, 113, 150, 240, 46, 85, 61, 2, 195, 166, 146,
  233, 195, 239, 138, 178, 52, 83, 230, 240, 116, 156, 214, 54, 231, 168, 142,
  97, 166, 147, 110, 78, 143, 16, 28, 28, 193, 249, 147, 181, 66, 160, 212,
  226, 116, 14, 138, 250, 212, 228, 209, 93, 13, 102, 27, 56, 46, 202, 137,
  163, 126, 223, 63, 151, 90, 186, 239, 147, 123, 98, 199, 141, 91, 177, 87,
  151, 75, 65, 39, 56, 229, 15, 69, 199, 249, 219, 37, 65, 63, 39, 75,
  208, 162, 0, 254, 244, 105, 36, 164, 184, 45, 255, 248, 83, 142, 193, 182,
  199, 119, 241, 167, 85, 45, 86, 7, 34, 174, 22, 92, 74, 5, 30, 103,
  176, 176, 245, 123, 203, 151, 183, 131, 161, 83, 143, 247, 142, 154, 104, 194,
  251, 169, 135, 89, 78, 141, 15, 71, 20, 5, 107, 103, 72, 119, 235, 57,
  220, 159, 1, 253, 118, 184, 124, 13, 15, 75, 232, 133, 11, 11, 236, 224,
  96, 13, 7, 163, 185, 178, 196, 228, 8, 33, 83, 214, 209, 112, 122, 166,
  215, 194, 85, 63, 70, 31, 240, 64, 5, 5, 168, 177, 207, 131, 64, 147,
  114, 99, 43, 198, 1, 8, 198, 197, 140, 23, 251, 103, 171, 99, 171, 149,
  237, 175, 158, 87, 208, 69, 172, 133, 127, 2, 63, 157, 194, 56, 177, 78,
  146, 0, 205, 141, 35, 150, 128, 203, 90, 105, 230, 84, 64, 50, 99, 20,
]);
