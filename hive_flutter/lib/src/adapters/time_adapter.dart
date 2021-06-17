part of '../../adapters.dart';

class TimeAdapter extends TypeAdapter<TimeOfDay> {
  @override
  TimeOfDay read(BinaryReader reader) => reader.read() as TimeOfDay;

  @override
  void write(BinaryWriter writer, TimeOfDay obj) => writer.write(obj);

  @override
  int get typeId => 201;
}
