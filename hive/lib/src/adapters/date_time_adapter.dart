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
