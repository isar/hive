import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/decryption_cbc.dart';
import 'package:hive/src/crypto/encryption_cbc.dart';
import 'package:test/test.dart';

import 'message.dart';

void main() {
  group('EncryptionCBC', () {
    group('.init()', () {
      test('resets state', () {
        var out1 = Uint8List(16);
        var out2 = Uint8List(16);
        var cbc = EncryptionCBC(encryptionKey);

        cbc.init(iv);
        cbc.processBlock(message, 0, out1, 0);

        cbc.init(iv);
        cbc.processBlock(message, 0, out2, 0);

        expect(out1, out2);
      });

      test('validates iv length', () {
        expect(() => EncryptionCBC(encryptionKey).init(Uint8List(15)),
            throwsA(anything));
      });
    });

    test('.processBlock()', () {
      var out = Uint8List(256);
      var cbc = EncryptionCBC(encryptionKey)..init(iv);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        cbc.processBlock(message, i, out, i);
      }
      expect(out, encrypted);
    });
  });

  group('DecryptionCBC', () {
    group('.init()', () {
      test('resets state', () {
        var out1 = Uint8List(16);
        var out2 = Uint8List(16);
        var cbc = DecryptionCBC(decryptionKey);

        cbc.init(iv);
        cbc.processBlock(encrypted, 0, out1, 0);

        cbc.init(iv);
        cbc.processBlock(encrypted, 0, out2, 0);

        expect(out1, out2);
      });

      test('validates iv length', () {
        expect(() => DecryptionCBC(decryptionKey).init(Uint8List(15)),
            throwsA(anything));
      });
    });

    test('.processBlock()', () {
      var out = Uint8List(256);
      var cbc = DecryptionCBC(decryptionKey)..init(iv);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        cbc.processBlock(encrypted, i, out, i);
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

final encrypted = Uint8List.fromList([
  //
  224, 104, 0, 245, 122, 44, 51, 86, 147, 218, 180, 10, 3, 118, 150, 249,
  213, 108, 240, 204, 45, 251, 170, 21, 17, 89, 57, 73, 228, 246, 176, 69,
  119, 221, 160, 100, 184, 140, 183, 201, 9, 198, 35, 66, 78, 125, 142, 134,
  88, 59, 38, 155, 230, 223, 214, 119, 72, 52, 253, 16, 159, 73, 63, 119,
  252, 159, 52, 74, 44, 208, 151, 47, 18, 158, 186, 75, 219, 9, 16, 112,
  114, 63, 5, 185, 69, 55, 232, 41, 168, 2, 185, 7, 43, 98, 72, 211,
  3, 123, 209, 246, 59, 81, 237, 158, 183, 184, 136, 27, 196, 133, 120, 68,
  102, 122, 210, 139, 217, 124, 241, 61, 134, 35, 209, 63, 7, 51, 43, 172,
  21, 79, 203, 125, 75, 173, 17, 183, 67, 160, 253, 211, 245, 22, 217, 57,
  135, 230, 162, 244, 184, 66, 48, 61, 223, 82, 144, 33, 32, 16, 17, 139,
  182, 57, 109, 107, 169, 240, 31, 17, 128, 6, 170, 125, 104, 133, 161, 35,
  105, 81, 58, 59, 154, 4, 203, 192, 35, 89, 32, 93, 87, 86, 0, 137,
  221, 181, 59, 18, 6, 194, 98, 71, 36, 184, 61, 77, 24, 237, 97, 143,
  213, 237, 100, 132, 138, 236, 79, 100, 173, 53, 131, 186, 191, 219, 171, 99,
  136, 203, 229, 241, 130, 8, 14, 248, 123, 191, 148, 4, 211, 115, 157, 21,
  39, 207, 151, 94, 208, 238, 211, 83, 143, 196, 54, 197, 24, 195, 194, 5,
]);
