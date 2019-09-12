part of hive;

/// Saves enum as short string Days.Monday => "Monday"
class EnumAdapter<T> extends TypeAdapter<T> {
  final List<T> _values;
  EnumAdapter(this._values);
  
  @override
  T read(BinaryReader reader) {
    var string = reader.readString();
    return _values.firstWhere((value) => _describeEnum(value) == string,
        orElse: () => null);
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer.writeString(_describeEnum(obj));
  }
}

/// Saves enum as long string Days.Monday => "Days.Monday"
class EnumLongAdapter<T> extends TypeAdapter<T> {
  final List<T> _values;
  EnumLongAdapter(this._values);
  
  @override
  T read(BinaryReader reader) {
    var string = reader.readString();
    return _values.firstWhere((value) => value.toString() == string,
        orElse: () => null);
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer.writeString(obj.toString());
  }
}

/// Saves index of the enum. Use only when the enum never changes.
/// Use for enums such as Days, Months, etc.
class EnumIndexAdapter<T> extends TypeAdapter<T> {
  final List<T> _values;
  EnumIndexAdapter(this._values);
  
  @override
  T read(BinaryReader reader) {
    int index = reader.readUint32();
    return _values[index];
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer.writeUint32(_values.indexOf(obj));
  }
}

// from flutter
String _describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  return description.substring(indexOfDot + 1);
}

