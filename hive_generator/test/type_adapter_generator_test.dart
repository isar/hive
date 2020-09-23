import 'package:hive_generator/src/type_adapter_generator.dart';
import 'package:test/test.dart';

void main() {
  group('generateName', () {
    test('.generateName()', () {
      var name = r'_$User';
      expect(TypeAdapterGenerator.generateName(name), equals('UserAdapter'));
    });
  });
}
