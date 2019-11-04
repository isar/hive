import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class _ResolvedAdapter<T> {
  final TypeAdapter adapter;
  final int typeId;

  const _ResolvedAdapter(this.adapter, this.typeId);

  bool matches(dynamic value) => value is T;
}

class TypeRegistryImpl implements TypeRegistry {
  @visibleForTesting
  static const reservedTypeIds = 32;

  final TypeRegistryImpl parent;
  final _typeAdapters = <int, _ResolvedAdapter>{};

  TypeRegistryImpl([this.parent]);

  _ResolvedAdapter findAdapterForValue(dynamic value) {
    for (var adapter in _typeAdapters.values) {
      if (adapter.matches(value)) return adapter;
    }
    return parent?.findAdapterForValue(value);
  }

  _ResolvedAdapter findAdapterForTypeId(int typeId) {
    var adapter = _typeAdapters[typeId];
    return adapter ?? parent?.findAdapterForTypeId(typeId);
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, int typeId) {
    if (typeId < 0 || typeId > 223) {
      throw HiveError('TypeId $typeId not allowed.');
    }

    var updatedTypeId = typeId + reservedTypeIds;

    if (findAdapterForTypeId(updatedTypeId) != null) {
      throw HiveError('There is already a TypeAdapter for typeId $typeId.');
    }

    registerInternal(adapter, updatedTypeId);
  }

  void registerInternal<T>(TypeAdapter<T> adapter, int typeId) {
    var resolved = _ResolvedAdapter<T>(adapter, typeId);
    _typeAdapters[typeId] = resolved;
  }

  void resetAdapters() {
    _typeAdapters.clear();
  }
}
