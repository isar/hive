// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnimalAdapter extends TypeAdapter<Animal> {
  @override
  final int typeId = 3;

  @override
  Animal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Animal(
      field1: fields[1] as int,
      field0: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Animal obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.field0)
      ..writeByte(1)
      ..write(obj.field1);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnimalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CatAdapter extends TypeAdapter<Cat> {
  @override
  final int typeId = 5;

  @override
  Cat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cat(
      field2: fields[2] as String,
      field0: fields[0] as String,
      field1: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Cat obj) {
    writer
      ..writeByte(3)
      ..writeByte(2)
      ..write(obj.field2)
      ..writeByte(0)
      ..write(obj.field0)
      ..writeByte(1)
      ..write(obj.field1);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TigerAdapter extends TypeAdapter<Tiger> {
  @override
  final int typeId = 6;

  @override
  Tiger read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tiger(
      fields[3] as int,
      field2: fields[2] as String,
      field0: fields[0] as String,
      field1: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Tiger obj) {
    writer
      ..writeByte(4)
      ..writeByte(3)
      ..write(obj.field3)
      ..writeByte(2)
      ..write(obj.field2)
      ..writeByte(0)
      ..write(obj.field0)
      ..writeByte(1)
      ..write(obj.field1);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TigerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
