import '../../hive.dart';
import 'type_registry_impl.dart';

/// Not part of public API
///
/// Read/write values as in TypeRegistryImpl
/// but have own typeId for parent registry
class NestedTypeRegistryAdapterImpl extends TypeRegistryImpl
    implements TypeAdapter<dynamic> {
  @override
  final int typeId;

  NestedTypeRegistryAdapterImpl(this.typeId);

  @override
  dynamic read(BinaryReader reader) {
    final typeId = reader.readByte();
    final resolved = findAdapterForTypeId(typeId);

    if (resolved == null) {
      throw HiveError(
        'Nested type registry can not read, unknown typeId: $typeId. '
        'Did you forget to register an adapter?',
      );
    }

    return resolved.adapter.read(reader);
  }

  @override
  void write(BinaryWriter writer, dynamic obj) {
    final resolved = findAdapterForValue(obj);
    if (resolved == null) {
      throw HiveError(
        'Nested type registry can not write, unknown type: ${obj.runtimeType}. '
        'Did you forget to register an adapter?',
      );
    }

    writer.writeByte(resolved.typeId);
    resolved.adapter.write(writer, obj);
  }

  @override
  void registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool internal = false,
    bool override = false,
  }) {
    assert(internal == false,
        'A nested TypeRegistry could not be used for internal types.');
    super.registerAdapter(adapter, internal: internal, override: override);
  }

  @override
  int resolveTypeId(int typeId, {bool internal = false}) {
    // Nested type registries does not need to reserve typeId space for the
    // internal types. That's why we can use the whole typeId space of 256
    // values instead of 223.
    return typeId;
  }
}
