import 'package:hive/hive.dart';

class TypeRegistryImpl implements TypeRegistry {
  final TypeRegistry parent;
  final _typeAdapters = <int, ResolvedAdapter>{};

  TypeRegistryImpl([this.parent]);

  @override
  ResolvedAdapter findAdapterForValue(dynamic value) {
    for (var adapter in _typeAdapters.values) {
      if (adapter.matches(value)) return adapter;
    }
    return parent?.findAdapterForValue(value);
  }

  @override
  ResolvedAdapter findAdapterForTypeId(int typeId) {
    var adapter = _typeAdapters[typeId];
    return adapter ?? parent?.findAdapterForTypeId(typeId);
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, int typeId) {
    if (typeId < TypeRegistry.minCustomTypeId || typeId > 255) {
      throw HiveError('TypeId $typeId not allowed.');
    }

    if (findAdapterForTypeId(typeId) != null) {
      throw HiveError('There is already a TypeAdapter for typeId $typeId.');
    }

    registerInternal(adapter, typeId);
  }

  void registerInternal<T>(TypeAdapter<T> adapter, int typeId) {
    var resolved = ResolvedAdapter<T>(adapter, typeId);
    _typeAdapters[typeId] = resolved;
  }

  void resetAdapters() {
    _typeAdapters.clear();
  }
}
