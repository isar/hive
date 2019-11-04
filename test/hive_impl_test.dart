@TestOn('vm')

import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'common.dart';
import 'generated/frames.g.dart';

void main() {
  group('HiveImpl', () {
    Future<HiveImpl> initHive() async {
      var tempDir = await getTempDir();
      var hive = HiveImpl();
      hive.init(tempDir.path);
      return hive;
    }

    test('.init()', () {
      var hive = HiveImpl();

      hive.init('MYPATH');
      expect(hive.homePath, 'MYPATH');

      hive.init('OTHERPATH');
      expect(hive.homePath, 'OTHERPATH');

      expect(
        hive.findAdapterForValue(DateTime.now()).adapter,
        isA<DateTimeAdapter>(),
      );
      expect(hive.findAdapterForTypeId(16).adapter, isA<DateTimeAdapter>());
    });

    group('.openBox()', () {
      group('box already open', () {
        test('opened box is returned if it exists', () async {
          var hive = await initHive();

          var testBox = await hive.openBox('testBox');
          var testBox2 = await hive.openBox('testBox');
          expect(testBox == testBox2, true);

          await hive.close();
        });

        test('throw HiveError if opened box.isLazy != lazy', () async {
          var hive = await initHive();

          await hive.openBox('lazyBox', lazy: true);
          await expectLater(
            () => hive.openBox('lazyBox'),
            throwsHiveError('lazy and non-lazy at the same time'),
          );

          await hive.openBox('nonLazyBox');
          await expectLater(
            () => hive.openBox('nonLazyBox', lazy: true),
            throwsHiveError('lazy and non-lazy at the same time'),
          );

          await hive.close();
        });
      });

      test('home directory is created', () async {
        var tempDir = await getTempDir();
        var hive = HiveImpl();

        var hivePath = path.join(tempDir.path, 'somePath');
        hive.init(hivePath);

        await hive.openBox('testBox');
        expect(await Directory(hivePath).exists(), true);

        await hive.close();
      });

      test('throws HiveError if type arguments are set for lazy box', () async {
        var hive = await initHive();

        await expectLater(
          () => hive.openBox<int>('box', lazy: true),
          throwsHiveError('lazy boxes do not support type arguments'),
        );

        await hive.close();
      });
    });

    group('.openBoxFromBytes()', () {
      test('opened box is returned if it exists', () async {
        var hive = HiveImpl();
        var testBox = await hive.openMemoryBox('testBox', bytes: frameBytes[0]);
        var testBox2 = await hive.openMemoryBox('testBox');
        expect(testBox == testBox2, true);

        await hive.close();
      });
    });

    group('.box()', () {
      test('returns already opened box', () async {
        var hive = await initHive();

        var box = await hive.openBox('testBox');
        expect(hive.box('testBox'), box);
        expect(() => hive.box('other'), throwsHiveError('not found'));

        await hive.close();
      });

      test('throws HiveError if box type does not match', () async {
        var hive = await initHive();

        await hive.openBox<int>('intBox');
        expect(
          () => hive.box('intBox'),
          throwsHiveError('cannot open the same box as'),
        );
        expect(
          () => hive.box<double>('intBox'),
          throwsHiveError('cannot open the same box as'),
        );

        await hive.openBox('dynamicBox');
        expect(
          () => hive.box<int>('dynamicBox'),
          throwsHiveError('cannot open the same box as'),
        );

        await hive.close();
      });
    });

    test('isBoxOpen()', () async {
      var hive = await initHive();

      await hive.openBox('testBox');

      expect(hive.isBoxOpen('testBox'), true);
      expect(hive.isBoxOpen('nonExistingBox'), false);

      await hive.close();
    });

    test('.close()', () async {
      var hive = await initHive();

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
      var hive = await initHive();

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

      await hive.close();
    });
  });
}
