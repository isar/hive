import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  test('HiveType', () {
    var type = HiveType(typeId: 5, adapterName: 'Adapter');
    expect(type.typeId, 5);
    expect(type.adapterName, 'Adapter');
  });

  test('HiveField', () {
    var field = HiveField(1);
    expect(field.index, 1);
  });
}
