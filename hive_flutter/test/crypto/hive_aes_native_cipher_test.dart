import 'dart:math';

import 'package:hive_flutter/adapters.dart';
import 'package:test/test.dart';

import 'directory.dart';

void main() {
  group('HiveAesNativeCbcCipher', () {
    late HiveAesNativeCbcCipher cipher;
    late Box box;
    late List<int> message;

    setUp(() async {
      final random = Random.secure();
      cipher = HiveAesNativeCbcCipher(
        List.generate(32, (index) => random.nextInt(255)),
      );

      var dir = await getTempDir();
      Hive.init(dir.path);

      box = await Hive.openBox<List<int>>(boxName, encryptionCipher: cipher);

      message = List.generate(64, (index) => random.nextInt(255));
    });
    test('encrypt()', () async {
      final index = await box.add(message);

      await box.close();

      box = await Hive.openBox<List<int>>(boxName, encryptionCipher: cipher);
      final value = box.getAt(index);
      expect(value, message);
    });
  });
}
