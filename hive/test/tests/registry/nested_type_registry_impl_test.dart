import 'package:hive/hive.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

import '../common.dart';

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
  group('NestedTypeRegistryAdapterImpl', () {
    group('.registerAdapter()', () {
      test('register', () {
        var registry = TypeRegistryImpl();
        var nestedTypeRegistryAdapter =
            registry.createNestedTypeRegistryAdapter(2);

        var adapter = TestAdapter();
        nestedTypeRegistryAdapter.registerAdapter(adapter);
        registry.registerNestedTypeRegistryAdapter(nestedTypeRegistryAdapter);

        var resolved = registry.findAdapterForValue(123)!;
        expect(resolved.typeId, 32 + 2);
        expect(resolved.adapter, nestedTypeRegistryAdapter);
      });

      test('unsupported typeId', () {
        var registry = TypeRegistryImpl();
        var typeRegistryAdapter1 = registry.createNestedTypeRegistryAdapter(-1);
        var typeRegistryAdapter2 =
            registry.createNestedTypeRegistryAdapter(224);
        expect(
            () => registry
                .registerNestedTypeRegistryAdapter(typeRegistryAdapter1),
            throwsHiveError('not allowed'));
        expect(
            () => registry
                .registerNestedTypeRegistryAdapter(typeRegistryAdapter2),
            throwsHiveError('not allowed'));
      });

      test('duplicate typeId', () {
        var registry = TypeRegistryImpl();
        registry.registerNestedTypeRegistryAdapter(
            registry.createNestedTypeRegistryAdapter(1));
        expect(
            () => registry.registerNestedTypeRegistryAdapter(
                registry.createNestedTypeRegistryAdapter(1)),
            throwsHiveError('already a TypeAdapter for typeId'));
      });
    });

    test('.findAdapterForTypeId()', () {
      var registry = TypeRegistryImpl();
      var nestedTypeRegistryAdapter =
          registry.createNestedTypeRegistryAdapter(2);

      var adapter = TestAdapter();
      nestedTypeRegistryAdapter.registerAdapter(adapter);
      registry.registerNestedTypeRegistryAdapter(nestedTypeRegistryAdapter);

      var resolved = registry.findAdapterForTypeId(32 + 2)!;
      expect(resolved.typeId, 32 + 2);
      expect(resolved.adapter, nestedTypeRegistryAdapter);
    });

    group('.findAdapterForValue()', () {
      test('finds adapter', () {
        var registry = TypeRegistryImpl();
        var nestedTypeRegistryAdapter =
            registry.createNestedTypeRegistryAdapter(2);

        var adapter = TestAdapter();
        nestedTypeRegistryAdapter.registerAdapter(adapter);
        registry.registerNestedTypeRegistryAdapter(nestedTypeRegistryAdapter);

        var resolved = registry.findAdapterForValue(123)!;
        expect(resolved.typeId, 32 + 2);
        expect(resolved.adapter, nestedTypeRegistryAdapter);
      });

      test('returns first matching adapter', () {
        var registry = TypeRegistryImpl();
        var nestedTypeRegistryAdapter =
            registry.createNestedTypeRegistryAdapter(2);

        var adapter = TestAdapter();
        nestedTypeRegistryAdapter.registerAdapter(adapter);
        registry.registerNestedTypeRegistryAdapter(nestedTypeRegistryAdapter);
        registry.registerAdapter(adapter);

        var resolved = registry.findAdapterForValue(123)!;
        expect(resolved.typeId, 32 + 2);
        expect(resolved.adapter, nestedTypeRegistryAdapter);
      });
    });

    test('.resetAdapters()', () {
      var registry = TypeRegistryImpl();
      var nestedTypeRegistryAdapter =
          registry.createNestedTypeRegistryAdapter(2);

      var adapter = TestAdapter();
      nestedTypeRegistryAdapter.registerAdapter(adapter);
      registry.registerNestedTypeRegistryAdapter(nestedTypeRegistryAdapter);

      registry.resetAdapters();
      expect(registry.findAdapterForValue(123), null);
    });

    group('.isAdapterRegistered()', () {
      test('returns false if adapter is not found', () {
        var registry = TypeRegistryImpl();

        expect(registry.isAdapterRegistered(0), false);
      });

      test('returns true if adapter is found', () {
        var registry = TypeRegistryImpl();
        var nestedTypeRegistryAdapter =
            registry.createNestedTypeRegistryAdapter(2);

        var adapter = TestAdapter();
        nestedTypeRegistryAdapter.registerAdapter(adapter);
        registry.registerNestedTypeRegistryAdapter(nestedTypeRegistryAdapter);

        expect(registry.isAdapterRegistered(2), true);
      });
    });
  });
}
