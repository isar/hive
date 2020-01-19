import 'dart:typed_data';

import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/crypto/decryption_cbc.dart';

class PaddedDecryptionCipher extends PaddedCipher with DecryptionCBC {
  PaddedDecryptionCipher(List<List<int>> workingKey) : super(workingKey);

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    // Decrypt last block and remove padding
    processBlock(workingKey, inp, inpOff, out, outOff);

    var count = padCount(out.sublist(outOff));

    var padOffsetInBlock = blockSize - count;

    out.fillRange(outOff + padOffsetInBlock, out.length, count);

    return padOffsetInBlock;
  }

  @override
  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks) {
    if ((data.length % blockSize) != 0) {
      throw ArgumentError(
          "Input data length must be a multiple of cipher's block size");
    }
    return numberOfInputBlocks;
  }
}
