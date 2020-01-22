import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/crypto/padded_cipher.dart';
import 'package:meta/meta.dart';

class DecryptionPKCS7 extends PaddedCipher {
  DecryptionPKCS7(Cipher cipher) : super(cipher);

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    // Decrypt last block and remove padding
    cipher.processBlock(inp, inpOff, out, outOff);

    var count = padCount(out.sublist(outOff));

    var padOffsetInBlock = aesBlockSize - count;

    out.fillRange(outOff + padOffsetInBlock, out.length, count);

    return padOffsetInBlock;
  }

  @override
  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks) {
    if ((data.length % aesBlockSize) != 0) {
      throw ArgumentError(
          "Input data length must be a multiple of cipher's block size");
    }
    return numberOfInputBlocks;
  }

  @protected
  @visibleForTesting
  int padCount(Uint8List data) {
    var count = data[data.length - 1];

    if (count > data.length || count == 0) {
      throw ArgumentError('Invalid or corrupted pad block');
    }

    for (var i = 1; i <= count; i++) {
      if (data[data.length - i] != count) {
        throw ArgumentError('Invalid or corrupted pad block');
      }
    }

    return count;
  }
}
