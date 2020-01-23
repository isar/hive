import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:test/test.dart';

import 'message.dart';

void main() {
  group('AESEngine', () {
    test('.generateWorkingKey()', () {
      expect(generateWorkingKey(key, true), encryptionKey);
      expect(generateWorkingKey(key, false), decryptionKey);
    });

    test('.encryptBlock()', () {
      var out = Uint8List(message.length);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        //encryptBlock(encryptionKey, message, i, out, i);
      }
      //expect(out, encrypted);
    });

    test('.decryptBlock()', () {
      var out = Uint8List(256);
      for (var i = 0; i < message.length; i += aesBlockSize) {
        //decryptBlock(decryptionKey, encrypted, i, out, i);
      }
      //expect(out, message);
    });
  });
}
