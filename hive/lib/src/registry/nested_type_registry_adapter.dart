part of hive;

abstract class NestedTypeRegistryAdapter implements TypeAdapter, TypeRegistry {}


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

