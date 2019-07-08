part of hive;

class ResolvedAdapter {
  final TypeAdapter adapter;
  final int typeId;

  const ResolvedAdapter(this.adapter, this.typeId);
}

abstract class TypeRegistry {
  static const minCustomTypeId = 33;

  ResolvedAdapter findAdapterForTypeId(int typeId);

  ResolvedAdapter findAdapterForType(Type type);

  void registerAdapter<T>(TypeAdapter<T> adapter, int typeId);
}
