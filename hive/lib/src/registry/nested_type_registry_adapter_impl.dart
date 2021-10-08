import '../../hive.dart';
import 'type_registry_impl.dart';

/// read/write values as in TypeRegistryImpl
/// but have own typeId for parent registry
class NestedTypeRegistryAdapterImpl extends TypeRegistryImpl
    implements NestedTypeRegistryAdapter {
  @override
  final int typeId;

  NestedTypeRegistryAdapterImpl({
    required this.typeId,
  });

  @override
  dynamic read(BinaryReader reader) {
    var typeId = reader.readByte();

    var adapterForTypeId = findAdapterForTypeId(typeId);

    return adapterForTypeId!.adapter.read(reader);
  }

  @override
  void write(BinaryWriter writer, dynamic obj) {
    var adapterForValue = findAdapterForValue(obj);

    writer.writeByte(adapterForValue!.typeId);

    adapterForValue.adapter.write(writer, obj);
  }
}
