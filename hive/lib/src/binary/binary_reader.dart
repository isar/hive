part of hive;

abstract class BinaryReader {
  static const utf8Decoder = Utf8Decoder();

  int get availableBytes;

  int get usedBytes;

  void skip(int bytes);

  int readByte();

  Uint8List viewBytes(int bytes);

  Uint8List readBytes(int bytes);

  int readWord();

  int readInt32();

  int readUint32();

  int readInt();

  double readDouble();

  bool readBool();

  String readString([
    int byteCount,
    Converter<List<int>, String> decoder = utf8Decoder,
  ]);

  String readAsciiString([int length]);

  List<int> readIntList([int length]);

  List<double> readDoubleList([int length]);

  List<bool> readBoolList([int length]);

  List<String> readStringList([
    int length,
    Converter<List<int>, String> decoder = utf8Decoder,
  ]);

  List readList([int length]);

  Map readMap([int length]);

  dynamic read([int typeId]);
}
