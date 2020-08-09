import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'message.dart';

void main() {
  group('HiveAesCipher', () {
    group('create', () {
      test('creates instance', () {
        expect(HiveAesCipher(key), isNotNull);
      });

      test('throws ArgumentError if key is invalid', () {
        expect(HiveAesCipher([1, 2, 3, -1, 256]), throwsArgumentError);
      });
    });
  });

  // other methods are already tested on different tests
}
