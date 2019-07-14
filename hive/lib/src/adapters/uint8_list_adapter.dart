import 'dart:typed_data';

import 'package:hive/hive.dart';

class Uint8ListAdapter extends TypeAdapter<Uint8List> {
  @override
  Uint8List read(BinaryReader reader) {
    var length = reader.readWord();
    return reader.readBytes(length);
  }

  @override
  void write(BinaryWriter writer, Uint8List obj) {
    writer.writeWord(obj.length);
    writer.writeBytes(obj);
  }
}
