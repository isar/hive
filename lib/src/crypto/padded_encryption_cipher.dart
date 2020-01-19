import 'dart:typed_data';

import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/crypto/encryption_cbc.dart';

class PaddedEncryptionCipher extends PaddedCipher with EncryptionCBC {
  PaddedEncryptionCipher(List<List<int>> workingKey) : super(workingKey);

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    //var lastInputBlock = inp.sublist(inpOff, bö)
    var lastInputBlock = Uint8List(blockSize)..setAll(0, inp.sublist(inpOff));

    var remainder = inp.length - inpOff;

    if (remainder < blockSize) {
      // Padding goes embedded in last block of data
      addPadding(lastInputBlock, (inp.length - inpOff));

      processBlock(workingKey, lastInputBlock, 0, out, outOff);

      return blockSize;
    } else {
      // Padding goes alone in an additional block
      processBlock(workingKey, inp, inpOff, out, outOff);

      addPadding(lastInputBlock, 0);

      processBlock(workingKey, lastInputBlock, 0, out, outOff + blockSize);

      return 2 * blockSize;
    }
  }

  @override
  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks) {
    return (data.length + blockSize) ~/ blockSize;
  }
}
