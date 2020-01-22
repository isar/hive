import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/crypto/padded_cipher.dart';
import 'package:meta/meta.dart';

class PaddedEncryptionCipher extends PaddedCipher {
  PaddedEncryptionCipher(Cipher cipher) : super(cipher);

  @override
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    //var lastInputBlock = inp.sublist(inpOff, bö)
    var lastInputBlock = Uint8List(aesBlockSize)
      ..setAll(0, inp.sublist(inpOff));

    var remainder = inp.length - inpOff;

    if (remainder < aesBlockSize) {
      // Padding goes embedded in last block of data
      addPadding(lastInputBlock, (inp.length - inpOff));

      cipher.processBlock(lastInputBlock, 0, out, outOff);

      return aesBlockSize;
    } else {
      // Padding goes alone in an additional block
      cipher.processBlock(inp, inpOff, out, outOff);

      addPadding(lastInputBlock, 0);

      cipher.processBlock(lastInputBlock, 0, out, outOff + aesBlockSize);

      return 2 * aesBlockSize;
    }
  }

  @override
  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks) {
    return (data.length + aesBlockSize) ~/ aesBlockSize;
  }

  @protected
  @visibleForTesting
  int addPadding(Uint8List data, int offset) {
    var code = data.length - offset;
    data.fillRange(offset, data.length, code);
    return code;
  }
}
