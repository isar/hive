import 'package:hive/hive.dart';
import 'package:hive/src/adapters/ignored_type_adapter.dart';
import 'package:hive/src/registry/nested_type_registry_adapter_impl.dart';
import 'package:meta/meta.dart';

class _NullTypeRegistry implements TypeRegistryImpl {
  const _NullTypeRegistry();

  @override
  Never get _typeAdapters => throw UnimplementedError();

  @override
  Never findAdapterForTypeId(int typeId) => throw UnimplementedError();

  @override
  Never findAdapterForValue(value) => throw UnimplementedError();

  @override
  Never ignoreTypeId<T>(int typeId) => throw UnimplementedError();

  @override
  Never isAdapterRegistered(int typeId, {bool internal = false}) =>
      throw UnimplementedError();

  @override
  Never registerAdapter<T>(TypeAdapter<T> adapter,
          {bool internal = false, bool override = false}) =>
      throw UnimplementedError();

  @override
  Never resetAdapters() => throw UnimplementedError();

  @override
  NestedTypeRegistryAdapter createNestedTypeRegistryAdapter(int typeId) =>
      throw UnimplementedError();

  @override
  void registerNestedTypeRegistryAdapter(
    NestedTypeRegistryAdapter adapter, {
    bool internal = false,
    bool override = false,
  }) =>
      throw UnimplementedError();

  @override
  void _checkIsPossibleToRegisterAdapter({
    required TypeAdapter adapter,
    required bool internal,
    required bool override,
  }) =>
      throw UnimplementedError();
}

/// Not part of public API
class TypeRegistryImpl implements TypeRegistry {
  /// Not part of public API
  static const TypeRegistryImpl nullImpl = _NullTypeRegistry();

  /// Not part of public API
  @visibleForTesting
  static const reservedTypeIds = 32;

  final _typeAdapters = <int, ResolvedAdapter>{};

  /// Not part of public API
  ResolvedAdapter? findAdapterForValue(dynamic value) {
    for (var adapter in _typeAdapters.values) {
      if (adapter.matches(value)) return adapter;
    }
    return null;
  }

  /// Not part of public API
  ResolvedAdapter? findAdapterForTypeId(int typeId) {
    return _typeAdapters[typeId];
  }

  @override
  void registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool internal = false,
    bool override = false,
  }) {
    if (adapter is NestedTypeRegistryAdapter) {
      throw ArgumentError(
        'use registerNestedTypeRegistryAdapter '
        'for NestedTypeRegistryAdapter',
      );
    }
    if (T == dynamic || T == Object) {
      print(
        'Registering type adapters for dynamic type is must be avoided, '
        'otherwise all the write requests to Hive will be handled by given '
        'adapter. Please explicitly provide adapter type on registerAdapter '
        'method to avoid this kind of issues. For example if you want to '
        'register MyTypeAdapter for MyType class you can call like this: '
        'registerAdapter<MyType>(MyTypeAdapter())',
      );
    }
    _checkIsPossibleToRegisterAdapter(
      adapter: adapter,
      internal: internal,
      override: override,
    );
    var typeId = adapter.typeId;
    if (!internal) {
      typeId = typeId + reservedTypeIds;
    }
    var resolved = ResolvedAdapter<T>(adapter, typeId);
    _typeAdapters[typeId] = resolved;
  }

  @override
  NestedTypeRegistryAdapter createNestedTypeRegistryAdapter(int typeId) =>
      NestedTypeRegistryAdapterImpl(typeId: typeId);

  @override
  void registerNestedTypeRegistryAdapter(
    NestedTypeRegistryAdapter adapter, {
    bool override = false,
  }) {
    var internal = false;

    _checkIsPossibleToRegisterAdapter(
      adapter: adapter,
      internal: internal,
      override: override,
    );

    var typeId = adapter.typeId;

    if (!internal) {
      typeId = typeId + reservedTypeIds;
    }

    var resolved = NestedTypeRegistryResolvedAdapter(
      adapter,
      typeId,
    );
    _typeAdapters[typeId] = resolved;
  }

  void _checkIsPossibleToRegisterAdapter({
    required TypeAdapter adapter,
    required bool internal,
    required bool override,
  }) {
    var typeId = adapter.typeId;
    if (!internal) {
      if (typeId < 0 || typeId > 223) {
        throw HiveError('TypeId $typeId not allowed.');
      }
      typeId = typeId + reservedTypeIds;

      var oldAdapter = findAdapterForTypeId(typeId);
      if (oldAdapter != null) {
        if (override) {
          print(
            'You are trying to override ${oldAdapter.runtimeType.toString()}'
            'with ${adapter.runtimeType.toString()} for typeId: '
            '${adapter.typeId}. Please note that overriding adapters might '
            'cause weird errors. Try to avoid overriding adapters unless not '
            'required.',
          );
        } else {
          throw HiveError('There is already a TypeAdapter for '
              'typeId ${typeId - reservedTypeIds}.');
        }
      }
    }
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
