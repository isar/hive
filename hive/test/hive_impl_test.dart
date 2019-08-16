@TestOn('vm')

import 'dart:io';

import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

void main() {
  group('HiveImpl', () {
    test('.home', () {
      var hive = HiveImpl();

      expect(() => hive.path, throwsHiveError('not initialized'));

      hive.init('MYPATH');
      expect(hive.path, 'MYPATH');
    });

    test('.init()', () {
      var hive = HiveImpl();

      hive.init('MYPATH');
      expect(hive.path, 'MYPATH');

      hive.init('OTHERPATH');
      expect(hive.path, 'OTHERPATH');

      expect(hive.findAdapterForType(DateTime).adapter, isA<DateTimeAdapter>());
      expect(hive.findAdapterForTypeId(16).adapter, isA<DateTimeAdapter>());
    });

    group('.openBox()', () {
      test('opened box is returned if it exists', () async {
        var tempDir = await getTempDir();
        var hive = HiveImpl();
        hive.init(tempDir.path);

        var testBox = await hive.openBox('testBox');
        var testBox2 = await hive.openBox('testBox');
        expect(testBox, testBox2);
      });

      test('home directory is created', () async {
        var tempDir = await getTempDir();
        var hive = HiveImpl();

        var hivePath = path.join(tempDir.path, 'somePath');
        hive.init(hivePath);
        await hive.openBox('testBox');

        expect(await Directory(hivePath).exists(), true);
      });
    });

    test('.box()', () async {
      var tempDir = await getTempDir();
      var hive = HiveImpl();
      hive.init(tempDir.path);

      var box = await hive.openBox('testBox');
      expect(hive.box('testBox'), box);
      expect(() => hive.box('other'), throwsHiveError('not found'));
    });

    test('isBoxOpen()', () async {
      var tempDir = await getTempDir();
      var hive = HiveImpl();
      hive.init(tempDir.path);

      await hive.openBox('testBox');

      expect(hive.isBoxOpen('testBox'), true);
      expect(hive.isBoxOpen('nonExistingBox'), false);
    });

    test('.close()', () async {
      var tempDir = await getTempDir();
      var hive = HiveImpl();
      hive.init(tempDir.path);

      var box1 = await hive.openBox('box1');
      var box2 = await hive.openBox('box2');
      expect(box1.isOpen, true);
      expect(box2.isOpen, true);

      await hive.close();
      expect(box1.isOpen, false);
      expect(box2.isOpen, false);
    });

    test('.generateSecureKey()', () {
      var hive = HiveImpl();

      var key1 = hive.generateSecureKey();
      var key2 = hive.generateSecureKey();

      expect(key1.length, 32);
      expect(key2.length, 32);
      expect(key1, isNot(key2));
    });

    test('.deleteFromDisk()', () async {
      var dir = await getTempDir();
      var hive = HiveImpl();
      hive.init(dir.path);

      var box1 = await hive.openBox('testBox1');
      await box1.put('key', 'value');
      var box1File = File(box1.path);

      var box2 = await hive.openBox('testBox2');
      await box2.put('key', 'value');
      var box2File = File(box1.path);

      await hive.deleteFromDisk();
      expect(await box1File.exists(), false);
      expect(await box2File.exists(), false);
      expect(hive.isBoxOpen('testBox1'), false);
      expect(hive.isBoxOpen('testBox2'), false);
    });
  });
}
