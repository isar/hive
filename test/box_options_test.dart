import 'package:hive/src/box_options.dart';
import 'package:test/test.dart';

void main() {
  test("no options", () {
    var options = BoxOptions();

    expect(options.version, 1);
  });

  test("valid encryption key", () {
    var validKey = List.filled(32, 0);
    BoxOptions(encryptionKey: validKey);

    var invalidKey = List.filled(31, 0);

    expect(() => BoxOptions(encryptionKey: invalidKey), throwsArgumentError);
  });

  test("valid version", () {
    var options = BoxOptions(version: 5);
    expect(options.version, 5);

    expect(() => BoxOptions(version: -1), throwsArgumentError);
  });
}
