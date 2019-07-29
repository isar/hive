import 'package:hive/src/box/box_options.dart';
import 'package:test/test.dart';

void main() {
  test('valid encryption key', () {
    var validKey = List.filled(32, 0);
    BoxOptions(encryptionKey: validKey);

    var invalidKey = List.filled(31, 0);

    expect(() => BoxOptions(encryptionKey: invalidKey), throwsArgumentError);
  });
}
