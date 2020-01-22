import 'dart:typed_data';

abstract class Cipher {
  void init(Uint8List iv);

  void processBlock(List<List<int>> workingKey, Uint8List inp, int inpOff,
      Uint8List out, int outOff);
}
