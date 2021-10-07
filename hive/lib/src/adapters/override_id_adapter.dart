import 'package:hive/hive.dart';

// Useful to override adapter during or move adapters ids from @HiveType
// to separate file to have all id's in one file
// OverrideIdAdapter(
//         100,
//         OriginalAdapter(),
// ),
class OverrideIdAdapter<T> extends TypeAdapter<T> {
  @override
  final int typeId;

  final TypeAdapter<T> adapter;

  OverrideIdAdapter(
    this.typeId,
    this.adapter,
  );

  @override
  T read(BinaryReader reader) => adapter.read(reader);

  @override
  void write(BinaryWriter writer, T obj) => adapter.write(writer, obj);
}
