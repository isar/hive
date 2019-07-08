import 'package:hive/hive.dart';

class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  DateTime read(BinaryReader reader) {
    var micros = reader.readInt();
    return DateTime.fromMicrosecondsSinceEpoch(micros);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.microsecondsSinceEpoch);
  }
}
