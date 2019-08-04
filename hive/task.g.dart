// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  Task read(BinaryReader reader) {
    var obj = Task();
    var numOfFields = reader.readByte();
    for (var i = 0; i < numOfFields; i++) {
      switch (reader.readByte()) {
        case 0:
          obj.title = reader.read() as String;
          break;
        case 1:
          obj.done = reader.read() as bool;
          break;
        case 2:
          obj.id = reader.read() as int;
          break;
      }
    }
    return obj;
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.title);
    writer.writeByte(1);
    writer.write(obj.done);
    writer.writeByte(2);
    writer.write(obj.id);
  }
}
