import 'package:hive/hive.dart';

/// Not part of public API
class IgnoredTypeAdapter<T> implements TypeAdapter<T> {
  IgnoredTypeAdapter([this._typeId = 0]);

  final int _typeId;

  @override
  T read(BinaryReader reader) {
    return null;
  }

  @override
  int get typeId => _typeId;

  @override
  void write(BinaryWriter writer, obj) {}
}
