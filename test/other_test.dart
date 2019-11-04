import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  test('test unnecessary code', () {
    const HiveField(0);
    const HiveType(adapterName: 'Adapter');
  });
}
