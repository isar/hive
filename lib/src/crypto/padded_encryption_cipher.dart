import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/crypto/padded_cipher.dart';

class PaddedEncryptionCipher extends PaddedCipher {
  PaddedEncryptionCipher(Cipher cipher, List<List<int>> workingKey)
      : super(cipher, workingKey);

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    //var lastInputBlock = inp.sublist(inpOff, bö)
    var lastInputBlock = Uint8List(aesBlockSize)
      ..setAll(0, inp.sublist(inpOff));

    var remainder = inp.length - inpOff;

    if (remainder < aesBlockSize) {
      // Padding goes embedded in last block of data
      addPadding(lastInputBlock, (inp.length - inpOff));

      cipher.processBlock(workingKey, lastInputBlock, 0, out, outOff);

      return aesBlockSize;
    } else {
      // Padding goes alone in an additional block
      cipher.processBlock(workingKey, inp, inpOff, out, outOff);

      addPadding(lastInputBlock, 0);

      cipher.processBlock(
          workingKey, lastInputBlock, 0, out, outOff + aesBlockSize);

      return 2 * aesBlockSize;
    }
  }

  @override
  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks) {
    return (data.length + aesBlockSize) ~/ aesBlockSize;
  }
}
