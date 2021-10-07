part of hive;

// special adapter to implement TypeRegistry inside other TypeRegistry
abstract class NestedTypeRegistryAdapter implements TypeAdapter, TypeRegistry {}

// Needed to catch which types registered in nested type Registry
class ResolvedNestedTypeRegistryResolvedAdapter extends ResolvedAdapter {
  @override
  final NestedTypeRegistryAdapter adapter;

  ResolvedNestedTypeRegistryResolvedAdapter(this.adapter, int typeId)
      : super(
    adapter,
    typeId,
  );

  bool matches(dynamic value) {
    var adapterForValue = adapter.findAdapterForValue(value);

    return adapterForValue != null;
  }
}

