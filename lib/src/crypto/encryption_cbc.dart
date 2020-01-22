import 'dart:typed_data';

import 'package:hive/src/crypto/aes_engine.dart';
import 'package:hive/src/crypto/cipher.dart';

class EncryptionCBC extends Cipher {
  Uint8List _cbcV;

  EncryptionCBC(List<List<int>> workingKey) : super(workingKey);

  @override
  void init(Uint8List iv) {
    assert(iv.length == aesBlockSize);
    _cbcV = Uint8List.fromList(iv);
  }

  @override
  void processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    // XOR the cbcV and the input, then encrypt the cbcV
    for (var i = 0; i < aesBlockSize; i++) {
      _cbcV[i] ^= inp[inpOff + i];
    }

    AESEngine.encryptBlock(workingKey, _cbcV, 0, out, outOff);

    // copy ciphertext to cbcV
    _cbcV.setRange(0, aesBlockSize, out, outOff);
  }
}
