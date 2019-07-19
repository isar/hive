part of hive;

@immutable
abstract class TypeAdapter<T> {
  T read(BinaryReader reader);

  void write(BinaryWriter writer, T obj);
}
