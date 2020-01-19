import 'dart:typed_data';
import 'package:hive/src/util/uint8_list_extension.dart';

final blockSize = 16;

abstract class Cipher {
  void init(Uint8List iv);

  void processBlock(List<List<int>> workingKey, Uint8List inp, int inpOff,
      Uint8List out, int outOff);
}

abstract class PaddedCipher extends Cipher {
  final List<List<int>> workingKey;

  PaddedCipher(this.workingKey);

  Uint8List process(Uint8List data) {
    var inputBlocks = (data.length + blockSize - 1) ~/ blockSize;

    var outputBlocks = numberOfOutputBlocks(data, inputBlocks);
    var out = Uint8List(outputBlocks * blockSize);

    for (var i = 0; i < inputBlocks - 1; i++) {
      var offset = i * blockSize;
      processBlock(workingKey, data, offset, out, offset);
    }

    var lastBlockOffset = ((inputBlocks - 1) * blockSize);
    var lastBlockSize = doFinal(data, lastBlockOffset, out, lastBlockOffset);

    return out.view(0, lastBlockOffset + lastBlockSize);
  }

  int numberOfOutputBlocks(Uint8List data, int numberOfInputBlocks);

  int doFinal(Uint8List inp, int inpOff, Uint8List out, int outOff);

  int addPadding(Uint8List data, int offset) {
    var code = data.length - offset;
    data.fillRange(offset, data.length, code);
    return code;
  }

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
