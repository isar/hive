import 'package:hive/hive.dart';

/// Adapter for DateTime
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 16;

  @override
  DateTime read(BinaryReader reader) {
    var micros = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(micros);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

/// Alternative adapter for DateTime with TimeZone info
class DateTimeWithTimezoneAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 16;

  @override
  DateTime read(BinaryReader reader) {
    var micros = reader.readInt();
    var isUtc = reader.availableBytes > 0 ? reader.readBool() : false;
    return DateTime.fromMillisecondsSinceEpoch(micros, isUtc: isUtc);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
    writer.writeBool(obj.isUtc);
  }
}
