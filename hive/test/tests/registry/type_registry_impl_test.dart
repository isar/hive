import 'package:hive/hive.dart';
import 'package:hive/src/adapters/ignored_type_adapter.dart';
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

class TestAdapter2 extends TypeAdapter<int> {
  @override
  int get typeId => 1;

  @override
  int read(BinaryReader reader) {
    return 5;
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
        registry.registerAdapter(adapter);

        var resolved = registry.findAdapterForValue(123)!;
        expect(resolved.typeId, 32);
        expect(resolved.adapter, adapter);
      });

      test('unsupported typeId', () {
        var registry = TypeRegistryImpl();
        expect(() => registry.registerAdapter(TestAdapter(-1)),
            throwsHiveException('not allowed'));
        expect(() => registry.registerAdapter(TestAdapter(224)),
            throwsHiveException('not allowed'));
      });

      test('duplicate typeId', () {
        var registry = TypeRegistryImpl();
        registry.registerAdapter(TestAdapter());
        expect(() => registry.registerAdapter(TestAdapter()),
            throwsHiveException('already a TypeAdapter for typeId'));
      });

      test('dynamic type', () {
        var registry = TypeRegistryImpl();
        registry.registerAdapter<dynamic>(TestAdapter());
      });
    });

    test('.findAdapterForTypeId()', () {
      var registry = TypeRegistryImpl();
      var adapter = TestAdapter();
      registry.registerAdapter(adapter);

      var resolvedAdapter = registry.findAdapterForTypeId(32)!;
      expect(resolvedAdapter.typeId, 32);
      expect(resolvedAdapter.adapter, adapter);
    });

    group('.findAdapterForValue()', () {
      test('finds adapter', () {
        var registry = TypeRegistryImpl();
        var adapter = TestAdapter();
        registry.registerAdapter(adapter);

        var resolvedAdapter = registry.findAdapterForValue(123)!;
        expect(resolvedAdapter.typeId, 32);
        expect(resolvedAdapter.adapter, adapter);
      });

      test('returns first matching adapter', () {
        var registry = TypeRegistryImpl();
        var adapter1 = TestAdapter(0);
        var adapter2 = TestAdapter(1);
        registry.registerAdapter(adapter1);
        registry.registerAdapter(adapter2);

        var resolvedAdapter = registry.findAdapterForValue(123)!;
        expect(resolvedAdapter.typeId, 32);
        expect(resolvedAdapter.adapter, adapter1);
      });
    });

    test('.resetAdapters()', () {
      var registry = TypeRegistryImpl();
      var adapter = TestAdapter();
      registry.registerAdapter(adapter);

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
        var adapter = TestAdapter();
        registry.registerAdapter(adapter);

        expect(registry.isAdapterRegistered(0), true);
      });

      test('unsupported typeId', () {
        var registry = TypeRegistryImpl();
        expect(() => registry.isAdapterRegistered(-1),
            throwsHiveException('not allowed'));
        expect(() => registry.isAdapterRegistered(224),
            throwsHiveException('not allowed'));
      });
    });

    group('.ignoreTypeId()', () {
      test('registers IgnoredTypeAdapter', () {
        var registry = TypeRegistryImpl();
        registry.ignoreTypeId(0);
        var resolved = registry.findAdapterForTypeId(32)!;
        expect(resolved.adapter is IgnoredTypeAdapter, true);
      });

      test('duplicte typeId', () {
        var registry = TypeRegistryImpl();
        registry.registerAdapter(TestAdapter());
        expect(() => registry.ignoreTypeId(0),
            throwsHiveException('already a TypeAdapter for typeId'));
      });
    });
  });
}
