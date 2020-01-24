import 'dart:math';
import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/crc32.dart';
import 'package:hive/src/crypto/sha256.dart';
import 'package:hive/src/util/extensions.dart';

class PaddedCipher {
  static final _lastInputBlockBuffer = Uint8List(16);
  static final _ivRandom = Random.secure();

  final Uint8List keyBytes;

  List<Uint32List> _encryptionKey;
  List<Uint32List> _decryptionKey;

  PaddedCipher(this.keyBytes) {
    if (keyBytes.length != 32 || keyBytes.any((it) => it < 0 || it > 255)) {
      throw ArgumentError(
          'The encryption key has to be a 32 byte (256 bit) array.');
    }
  }

  int get keyCrc => Crc32.compute(Sha256.compute(keyBytes));

  Uint8List generateIV() => _ivRandom.nextBytes(16);

  int encrypt(Uint8List iv, Uint8List inp, int inpOff, int inpLength,
      Uint8List out, int outOff) {
    _encryptionKey ??= AESEngine.generateWorkingKey(keyBytes, true);

    var cbcV = Uint8List.fromList(iv);

    var inputBlocks = (inpLength + aesBlockSize) ~/ aesBlockSize;
    var remaining = inpLength % aesBlockSize;

    var offset = 0;
    for (var i = 0; i < inputBlocks - 1; i++) {
      // XOR the cbcV and the input, then encrypt the cbcV
      for (var i = 0; i < aesBlockSize; i++) {
        cbcV[i] ^= inp[inpOff + offset + i];
      }

      AESEngine.encryptBlock(_encryptionKey, cbcV, 0, out, outOff + offset);

      // copy ciphertext to cbcV
      cbcV.setRange(0, aesBlockSize, out, outOff + offset);
      offset += aesBlockSize;
    }

    var lastInputBlock = _lastInputBlockBuffer;
    lastInputBlock.setRange(0, remaining, inp, inpOff + offset);
    lastInputBlock.fillRange(remaining, aesBlockSize, aesBlockSize - remaining);

    for (var i = 0; i < aesBlockSize; i++) {
      cbcV[i] ^= lastInputBlock[i];
    }
    AESEngine.encryptBlock(_encryptionKey, cbcV, 0, out, outOff + offset);

    return offset + aesBlockSize;
  }

  int decrypt(Uint8List iv, Uint8List inp, int inpOff, int inpLength,
      Uint8List out, int outOff) {
    _decryptionKey ??= AESEngine.generateWorkingKey(keyBytes, false);

    var inputBlocks = (inpLength + aesBlockSize - 1) ~/ aesBlockSize;

    var offset = 0;

    AESEngine.decryptBlock(_decryptionKey, inp, inpOff, out, outOff);
    for (var i = 0; i < aesBlockSize; i++) {
      out[outOff + i] ^= iv[i];
    }
    offset += aesBlockSize;

    for (var i = 0; i < inputBlocks - 1; i++) {
      AESEngine.decryptBlock(
          _decryptionKey, inp, inpOff + offset, out, outOff + offset);
      for (var i = 0; i < aesBlockSize; i++) {
        out[outOff + offset + i] ^= inp[inpOff - aesBlockSize + offset + i];
      }
      offset += aesBlockSize;
    }

    var lastDecryptedByte = out[outOff + offset - 1];
    if (lastDecryptedByte > aesBlockSize) {
      throw ArgumentError('Invalid or corrupted pad block');
    }
    for (var i = 0; i < lastDecryptedByte; i++) {
      if (out[outOff + offset - i - 1] != lastDecryptedByte) {
        throw ArgumentError('Invalid or corrupted pad block');
      }
    }

    return offset - lastDecryptedByte;
  }
}
