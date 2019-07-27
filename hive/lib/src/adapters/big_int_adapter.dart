import 'dart:typed_data';

import 'package:hive/hive.dart';

var _byteMask = BigInt.from(0xff);

class BigIntAdapter extends TypeAdapter<BigInt> {
  @override
  BigInt read(BinaryReader reader) {
    var len = reader.readByte();
    var sign = reader.readByte();
    var bytes = reader.readByteList(len);
    var result = BigInt.from(0);
    for (var i = 0; i < len; i++) {
      result += BigInt.from(bytes[i]) << (8 * i);
    }
    if (sign > 0) {
      return -result;
    } else {
      return result;
    }
  }

  @override
  void write(BinaryWriter writer, BigInt obj) {
    var size = (obj.bitLength + 7) >> 3 + 1;
    var bytes = Uint8List(size);

    bytes[0] = obj.sign == -1 ? 1 : 0;
    obj = obj.toUnsigned(obj.bitLength);

    for (var i = 0; i < size; i++) {
      bytes[i] = (obj & _byteMask).toInt();
      obj = obj >> 8;
    }

    writer.writeByte(size);
    writer.writeByteList(bytes, writeLength: false);
  }
}
