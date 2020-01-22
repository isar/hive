import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/crypto/padded_cipher.dart';

class PaddedDecryptionCipher extends PaddedCipher {
  PaddedDecryptionCipher(Cipher cipher, List<List<int>> workingKey)
      : super(cipher, workingKey);

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    // Decrypt last block and remove padding
    cipher.processBlock(workingKey, inp, inpOff, out, outOff);

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
}
