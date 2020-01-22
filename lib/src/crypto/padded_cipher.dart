import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/cipher.dart';
import 'package:hive/src/util/uint8_list_extension.dart';
import 'package:meta/meta.dart';

abstract class PaddedCipher {
  final Cipher cipher;
  final List<List<int>> workingKey;

  PaddedCipher(this.cipher, this.workingKey);

  void init(Uint8List iv) {
    cipher.init(iv);
  }

  Uint8List process(Uint8List data) {
    var inputBlocks = (data.length + aesBlockSize - 1) ~/ aesBlockSize;

    var outputBlocks = numberOfOutputBlocks(data, inputBlocks);
    var out = Uint8List(outputBlocks * aesBlockSize);

    for (var i = 0; i < inputBlocks - 1; i++) {
      var offset = i * aesBlockSize;
      cipher.processBlock(workingKey, data, offset, out, offset);
    }

    var lastBlockOffset = ((inputBlocks - 1) * aesBlockSize);
    var lastBlockSize = doFinal(data, lastBlockOffset, out, lastBlockOffset);

    return out.view(0, lastBlockOffset + lastBlockSize);
  }

  @visibleForTesting
  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks);

  @visibleForTesting
  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff);

  @protected
  @visibleForTesting
  int addPadding(Uint8List data, int offset) {
    var code = data.length - offset;
    data.fillRange(offset, data.length, code);
    return code;
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
