import 'package:hive/hive.dart';
import 'package:hive/src/adapters/ignored_type_adapter.dart';
import 'package:hive/src/registry/nested_type_registry_adapter.dart';
import 'package:meta/meta.dart';

/// Not part of public API
///
/// Needed to codegen the TypeRegistry mock
class ResolvedAdapter<T> {
  final TypeAdapter adapter;
  final int typeId;

  ResolvedAdapter(this.adapter, this.typeId);

  bool matchesRuntimeType(dynamic value) => value.runtimeType == T;

  bool matchesType(dynamic value) => value is T;
}

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
  Never registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool internal = false,
    bool override = false,
  }) =>
      throw UnimplementedError();

  @override
  Never resetAdapters() => throw UnimplementedError();

  @override
  void registerNestedAdapters<T>(
    void Function(TypeRegistry registry) configure, {
    required int parentTypeId,
    bool override = false,
  }) =>
      throw UnimplementedError();

  @override
  void _checkIsPossibleToRegisterAdapter({
    required TypeAdapter adapter,
    required bool override,
    required int resolvedTypeId,
  }) =>
      throw UnimplementedError();

  @override
  int resolveTypeId(int typeId, {bool internal = false}) =>
      throw UnimplementedError();
}

/// Not part of public API
///
/// Wraps [ResolvedAdapter] for nested adapters.
class _ResolvedNestedAdapter extends ResolvedAdapter<dynamic> {
  final NestedTypeRegistryAdapterImpl registry;

  _ResolvedNestedAdapter(this.registry, int typeId) : super(registry, typeId);

  @override
  bool matchesRuntimeType(value) => registry.findAdapterForValue(value) != null;

  @override
  bool matchesType(value) => false;
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
    ResolvedAdapter? match;
    for (var resolved in _typeAdapters.values) {
      if (resolved.matchesRuntimeType(value)) {
        return resolved;
      }
      if (resolved.matchesType(value) && match == null) {
        match = resolved;
      }
    }
    return match;
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

    final typeId = resolveTypeId(adapter.typeId, internal: internal);

    _checkIsPossibleToRegisterAdapter(
      adapter: adapter,
      override: override,
      resolvedTypeId: typeId,
    );
    _typeAdapters[typeId] = ResolvedAdapter<T>(adapter, typeId);
  }

  @override
  void registerNestedAdapters<T>(
    void Function(TypeRegistry registry) configure, {
    required int parentTypeId,
    bool override = false,
  }) {
    final nestedRegistry = NestedTypeRegistryAdapterImpl(parentTypeId);
    final typeId = resolveTypeId(parentTypeId, internal: false);

    configure(nestedRegistry);

    _checkIsPossibleToRegisterAdapter(
      adapter: nestedRegistry,
      override: override,
      resolvedTypeId: typeId,
    );
    _typeAdapters[typeId] = _ResolvedNestedAdapter(nestedRegistry, typeId);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int resolveTypeId(int typeId, {bool internal = false}) {
    if (internal) {
      return typeId;
    }
    return typeId + reservedTypeIds;
  }

  void _checkIsPossibleToRegisterAdapter({
    required TypeAdapter adapter,
    required bool override,
    required int resolvedTypeId,
  }) {
    if (adapter.typeId < 0 || resolvedTypeId < 0 || resolvedTypeId > 255) {
      throw HiveError('TypeId $resolvedTypeId not allowed.');
    }

    var oldAdapter = findAdapterForTypeId(resolvedTypeId);
    if (oldAdapter != null) {
      if (override) {
        assert(() {
          print(
            'You are trying to override ${oldAdapter.runtimeType.toString()}'
            'with ${adapter.runtimeType.toString()} for typeId: '
            '${adapter.typeId}. Please note that overriding adapters might '
            'result with unexpected consequences. Try to avoid overriding '
            'adapters unless not required.',
          );
          return true;
        }());
      } else {
        throw HiveError(
            'There is already a TypeAdapter for typeId ${adapter.typeId}.');
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

  void resetAdapters() {
    _typeAdapters.clear();
  }

  @override
  void ignoreTypeId<T>(int typeId) {
    registerAdapter(IgnoredTypeAdapter<T>(typeId));
  }
}
