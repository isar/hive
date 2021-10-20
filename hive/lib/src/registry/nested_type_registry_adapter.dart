part of hive;

/// special adapter to implement TypeRegistry inside other TypeRegistry
abstract class NestedTypeRegistryAdapter implements TypeAdapter, TypeRegistry {}

/// Needed to catch which types registered in nested type Registry
class NestedTypeRegistryResolvedAdapter extends ResolvedAdapter {
  final NestedTypeRegistryAdapter nestedTypeRegistryAdapter;

  NestedTypeRegistryResolvedAdapter(
    this.nestedTypeRegistryAdapter,
    int id,
  ) : super(
          nestedTypeRegistryAdapter,
          id,
        );

  @override
  bool matches(dynamic value) {
    // NestedTypeRegistryResolvedAdapter matches value
    // if at least one nested adapter matches it
    var nestedAdapterForValue =
        nestedTypeRegistryAdapter.findAdapterForValue(value);

    var adapterForTypeExist = nestedAdapterForValue != null;

    return adapterForTypeExist;
  }
}
