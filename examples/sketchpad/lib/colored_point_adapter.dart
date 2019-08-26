import 'package:sketchpad/colored_point.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

class ColoredPointAdapter extends TypeAdapter<ColoredPoint> {
  @override
  ColoredPoint read(BinaryReader reader) {
    return ColoredPoint()
      ..colorIndex = reader.readByte()
      ..offset = Offset(reader.readDouble(), reader.readDouble());
  }

  @override
  void write(BinaryWriter writer, ColoredPoint obj) {
    writer.writeByte(obj.colorIndex);
    writer.writeDouble(obj.offset.dx);
    writer.writeDouble(obj.offset.dy);
  }
}
