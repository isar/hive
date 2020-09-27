import 'package:hive/hive.dart';

/// Adapter for DateTime
class DateTimeAdapter extends TypeAdapter<_DateTimeWithoutTZ> {
  @override
  final typeId = 16;

  @override
  _DateTimeWithoutTZ read(BinaryReader reader) {
    var micros = reader.readInt();
    return _DateTimeWithoutTZ.fromMillisecondsSinceEpoch(micros);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

class _DateTimeWithoutTZ extends DateTime {
  _DateTimeWithoutTZ.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch)
      : super.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

/// Alternative adapter for DateTime with time zone info
class DateTimeWithTimezoneAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 18;

  @override
  DateTime read(BinaryReader reader) {
    var micros = reader.readInt();
    var isUtc = reader.readBool();
    return DateTime.fromMillisecondsSinceEpoch(micros, isUtc: isUtc);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
    writer.writeBool(obj.isUtc);
  }
}
