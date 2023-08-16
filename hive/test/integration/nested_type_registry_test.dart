import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'integration.dart';

class TestObject {
  TestObject(this.value);

  final int value;
}

class TestAdapter extends TypeAdapter<TestObject> {
  TestAdapter();

  @override
  final int typeId = 10;

  @override
  TestObject read(BinaryReader reader) {
    return TestObject(reader.readInt32());
  }

  @override
  void write(BinaryWriter writer, obj) {
    writer.writeInt32(obj.value);
  }
}

void main() {
  test('uses nested TypeAdapters', () async {
    var hive = await createHive();
    var box1 = await hive.openBox('test');

    hive.registerNestedAdapters((registry) {
      registry.registerAdapter(TestAdapter());
    }, parentTypeId: 3);

    await box1.put('test', TestObject(5));
    await box1.close();

    var box2 = await hive.openBox('test');
    var testObject = box2.get('test');

    expect(testObject, isA<TestObject>());
    expect((testObject as TestObject).value, 5);
  });
}
