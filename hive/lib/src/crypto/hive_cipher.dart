part of hive;

abstract class HiveCipher {
  int calculateKeyCrc();

  int maxEncryptedSize(Uint8List inp);

  int encrypt(
      Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff);

  int decrypt(
      Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff);
}
