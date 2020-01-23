import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
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

      var pcEngine = AESFastEngine();
      var outPc = Uint8List(message.length);

      for (var i = 0; i < message.length; i += aesBlockSize) {
        encryptBlock(encryptionKey, message, i, out, i);
        pcEngine.init(true, KeyParameter(key));
        pcEngine.processBlock(message, i, outPc, i);
      }
      expect(out, outPc);
    });

    test('.decryptBlock()', () {
      var out = Uint8List(message.length);

      var pcEngine = AESFastEngine();
      var encrypted = Uint8List(message.length);

      for (var i = 0; i < message.length; i += aesBlockSize) {
        decryptBlock(encryptionKey, message, i, out, i);
        pcEngine.init(true, KeyParameter(key));
        pcEngine.processBlock(message, i, encrypted, i);
      }

      for (var i = 0; i < encrypted.length; i += aesBlockSize) {
        decryptBlock(decryptionKey, encrypted, i, out, i);
      }
      expect(out, message);
    });
  });
}
