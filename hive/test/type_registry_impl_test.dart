import 'package:hive/hive.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

import 'common.dart';

class TestAdapter extends TypeAdapter<int> {
  @override
  int read(BinaryReader reader) {
    // ignore: avoid_returning_null
    return null;
  }

  @override
  void write(BinaryWriter writer, obj) {}
}

class TestAdapter2 extends TypeAdapter<int> {
  @override
  int read(BinaryReader reader) {
    // ignore: avoid_returning_null
    return null;
  }

  @override
  void write(BinaryWriter writer, obj) {}
}

void main() {
  group('TypeRegistryImpl', () {
    group('.registerAdapter()', () {
      test('register', () {
        var registry = TypeRegistryImpl();
        var adapter = TestAdapter();
        registry.registerAdapter(adapter, 33);

        var resolvedAdapter = registry.findAdapterForType(int);
        expect(resolvedAdapter.typeId, 33);
        expect(resolvedAdapter.adapter, adapter);
      });

      test('too low typeId', () {
        var registry = TypeRegistryImpl();
        expect(
            () => registry.registerAdapter(
                TestAdapter(), TypeRegistry.minCustomTypeId - 1),
            throwsHiveError('not allowed'));
      });

      test('duplicate typeId', () {
        var registry = TypeRegistryImpl();
        registry.registerAdapter(TestAdapter(), 35);
        expect(() => registry.registerAdapter(TestAdapter(), 35),
            throwsHiveError('already a TypeAdapter for typeId'));
      });

      test('duplicate parent typeId', () {
        var parent = TypeRegistryImpl();
        var registry = TypeRegistryImpl(parent);

        parent.registerAdapter(TestAdapter(), 35);
        expect(() => registry.registerAdapter(TestAdapter(), 35),
            throwsHiveError('already a TypeAdapter for typeId'));
      });

      test('duplicate type', () {
        var registry = TypeRegistryImpl();
        var adapter1 = TestAdapter();
        registry.registerAdapter(adapter1, 35);
        var adapter2 = TestAdapter2();
        registry.registerAdapter(adapter2, 36);

        var resolvedAdapter = registry.findAdapterForType(int);
        expect(resolvedAdapter.typeId, 36);
        expect(resolvedAdapter.adapter, adapter2);
      });
    });

    group('.findAdapterForType() / .findAdapterForTypeId()', () {
      test('find', () {
        var registry = TypeRegistryImpl();
        var adapter = TestAdapter();
        registry.registerAdapter(adapter, 33);

        var resolvedAdapter = registry.findAdapterForType(int);
        expect(resolvedAdapter.typeId, 33);
        expect(resolvedAdapter.adapter, adapter);

        resolvedAdapter = registry.findAdapterForTypeId(33);
        expect(resolvedAdapter.typeId, 33);
        expect(resolvedAdapter.adapter, adapter);
      });

      test('find in parent', () {
        var parent = TypeRegistryImpl();
        var registry = TypeRegistryImpl(parent);
        var adapter = TestAdapter();
        parent.registerAdapter(adapter, 33);

        var resolvedAdapter = registry.findAdapterForType(int);
        expect(resolvedAdapter.typeId, 33);
        expect(resolvedAdapter.adapter, adapter);

        resolvedAdapter = registry.findAdapterForTypeId(33);
        expect(resolvedAdapter.typeId, 33);
        expect(resolvedAdapter.adapter, adapter);
      });

      test('prefer child', () {
        var parent = TypeRegistryImpl();
        var registry = TypeRegistryImpl(parent);

        var adapter1 = TestAdapter();
        parent.registerAdapter(adapter1, 33);

        var adapter2 = TestAdapter();
        registry.registerAdapter(adapter2, 34);

        var resolvedAdapter = registry.findAdapterForType(int);
        expect(resolvedAdapter.typeId, 34);
        expect(resolvedAdapter.adapter, adapter2);
      });
    });

    test('.resetAdapters()', () {
      var registry = TypeRegistryImpl();
      var adapter = TestAdapter();
      registry.registerAdapter(adapter, 33);

      registry.resetAdapters();
      expect(registry.findAdapterForType(int), null);
    });
  });
}
