import 'package:hive/hive.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

class TestAdapter extends TypeAdapter<int> {
  TestAdapter([this.typeId = 0]);

  @override
  final int typeId;

  @override
  int read(BinaryReader reader) {
    return 5;
  }

  @override
  void write(BinaryWriter writer, obj) {}
}

void main() {
  group('OverrideIdAdapter', () {
    test('.findAdapterForTypeId()', () {
      var registry = TypeRegistryImpl();
      var adapter = TestAdapter();
      var overrideIdAdapter = OverrideIdAdapter(1, adapter);
      registry.registerAdapter(overrideIdAdapter);

      var isAdapterRegisteredForOldId = registry.isAdapterRegistered(32);
      expect(isAdapterRegisteredForOldId, false);

      var resolvedAdapter = registry.findAdapterForTypeId(33)!;
      expect(resolvedAdapter.typeId, 33);
      expect(resolvedAdapter.adapter, overrideIdAdapter);
    });

    test('.findAdapterForValue()', () {
      var registry = TypeRegistryImpl();
      var adapter = TestAdapter();
      var overrideIdAdapter = OverrideIdAdapter(1, adapter);
      registry.registerAdapter(overrideIdAdapter);

      var resolvedAdapter = registry.findAdapterForValue(123)!;
      expect(resolvedAdapter.typeId, 33);
      expect(resolvedAdapter.adapter, overrideIdAdapter);
    });
  });
}
