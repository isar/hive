import 'dart:typed_data';

abstract class Cipher {
  final List<List<int>> workingKey;

  Cipher(this.workingKey);

  void init(Uint8List iv);

  void processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff);
}
