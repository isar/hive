part of hive;

abstract class BinaryWriter {
  static const utf8Encoder = Utf8Encoder();

  int get writtenBytes;

  void writeByte(int byte);

  void writeBytes(Uint8List bytes);

  void writeWord(int value);

  void writeInt32(int value);

  void writeUnsigenedInt32(int value);

  void writeInt(int value);

  void writeDouble(double value);

  void writeBool(bool value);

  void writeString(String value,
      {bool writeByteCount = true,
      Converter<String, List<int>> encoder = utf8Encoder});

  void writeAsciiString(String value, {bool writeLength = true});

  void writeIntList(List<int> list, {bool writeLength = true});

  void writeDoubleList(List<double> list, {bool writeLength = true});

  void writeBoolList(List<bool> list, {bool writeLength = true});

  void writeStringList(List<String> list,
      {bool writeLength = true,
      Converter<String, List<int>> encoder = utf8Encoder});

  void writeList(List list, {bool writeLength = true});

  void writeMap(Map map, {bool writeLength = true});

  void write(dynamic value, {bool writeTypeId = true});
}
