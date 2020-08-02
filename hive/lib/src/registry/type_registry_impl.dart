import 'package:hive/hive.dart';
import 'package:hive/src/registry/ignored_type_adapter.dart';
import 'package:meta/meta.dart';

class _ResolvedAdapter<T> {
  final TypeAdapter adapter;
  final int typeId;

  _ResolvedAdapter(this.adapter, this.typeId);

  bool matches(dynamic value) => value is T;
}

/// Not part of public API
class TypeRegistryImpl implements TypeRegistry {
  /// Not part of public API
  @visibleForTesting
  static const reservedTypeIds = 32;

  final _typeAdapters = <int, _ResolvedAdapter>{};

  /// Not part of public API
  _ResolvedAdapter findAdapterForValue(dynamic value) {
    for (var adapter in _typeAdapters.values) {
      if (adapter.matches(value)) return adapter;
    }
    return null;
  }

  /// Not part of public API
  _ResolvedAdapter findAdapterForTypeId(int typeId) {
    return _typeAdapters[typeId];
  }

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, {bool internal = false}) {
    var typeId = adapter.typeId;
    if (!internal) {
      if (typeId < 0 || typeId > 223) {
        throw HiveError('TypeId $typeId not allowed.');
      }
      typeId = typeId + reservedTypeIds;

      if (findAdapterForTypeId(typeId) != null) {
        throw HiveError('There is already a TypeAdapter for '
            'typeId ${typeId - reservedTypeIds}.');
      }
    }

    var resolved = _ResolvedAdapter<T>(adapter, typeId);
    _typeAdapters[typeId] = resolved;
  }

  @override
  bool isAdapterRegistered(int typeId, {bool internal = false}) {
    if (!internal) {
      if (typeId < 0 || typeId > 223) {
        throw HiveError('TypeId $typeId not allowed.');
      }

      typeId = typeId + reservedTypeIds;
    }

    return findAdapterForTypeId(typeId) != null;
  }

  /// Not part of public API
  void resetAdapters() {
    _typeAdapters.clear();
  }

  @override
  void ignoreTypeId<T>(int typeId) {
    registerAdapter(IgnoredTypeAdapter<T>(typeId));
  }
}
