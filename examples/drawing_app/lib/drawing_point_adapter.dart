import 'package:drawing_app/drawing_point.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

class DrawingPointAdapter extends TypeAdapter<DrawingPoint> {
  @override
  DrawingPoint read(BinaryReader reader) {
    return DrawingPoint()
      ..colorIndex = reader.readByte()
      ..point = Offset(reader.readDouble(), reader.readDouble());
  }

  @override
  void write(BinaryWriter writer, DrawingPoint obj) {
    writer.writeByte(obj.colorIndex);
    writer.writeDouble(obj.point.dx);
    writer.writeDouble(obj.point.dy);
  }
}
