// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 2;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.customer;
      case 1:
        return UserRole.contentEditor;
      case 2:
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.customer:
        writer.writeByte(0);
        break;
      case UserRole.contentEditor:
        writer.writeByte(1);
        break;
      case UserRole.admin:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 1;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person()
      ..firstName = fields[0] as String?
      ..lastName = fields[1] as String?
      ..birthday = fields[2] as DateTime?
      ..roles = (fields[3] as List?)?.cast<UserRole>()
      ..friends = (fields[4] as HiveList?)?.castHiveList();
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.birthday)
      ..writeByte(3)
      ..write(obj.roles)
      ..writeByte(4)
      ..write(obj.friends);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
