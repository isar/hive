import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class _ResolvedAdapter<T> {
  final TypeAdapter adapter;
  final int typeId;

  _ResolvedAdapter(this.adapter, this.typeId);

  bool matches(dynamic value) => value is T;
}

class TypeRegistryImpl implements TypeRegistry {
  @visibleForTesting
  static const reservedTypeIds = 32;

  final _typeAdapters = <int, _ResolvedAdapter>{};

  _ResolvedAdapter findAdapterForValue(dynamic value) {
    for (var adapter in _typeAdapters.values) {
      if (adapter.matches(value)) return adapter;
    }
    return null;
  }

  _ResolvedAdapter findAdapterForTypeId(int typeId) {
    return _typeAdapters[typeId];
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, [int typeId]) {
    if (adapter.typeId < 0 || adapter.typeId > 223) {
      throw HiveError('TypeId ${adapter.typeId} not allowed.');
    }

    var updatedTypeId = adapter.typeId + reservedTypeIds;

    if (findAdapterForTypeId(updatedTypeId) != null) {
      throw HiveError('There is already a TypeAdapter for typeId $typeId.');
    }

    registerInternal(adapter);
  }

  void registerInternal<T>(TypeAdapter<T> adapter) {
    var resolved = _ResolvedAdapter<T>(adapter, adapter.typeId);
    _typeAdapters[adapter.typeId] = resolved;
  }

  void resetAdapters() {
    _typeAdapters.clear();
  }
}
