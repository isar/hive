import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'util/is_browser.dart';

Future<Box> getBox(bool lazy) async {
  var hive = HiveImpl();
  if (!isBrowser) {
    var dir = await getTempDir();
    hive.init(dir.path);
  }
  return await hive.openBox('box', lazy: lazy);
}

Future<Box> reopenBox(Box box) async {
  await box.close();
  var hive = (box as BoxBase).hive;
  return await hive.openBox('box', lazy: box.lazy);
}

const longTimeout = Timeout(Duration(minutes: 2));

void main() {
  group('Integration tests', () {
    group('put large lists', () {
      Future performTest(bool lazy) async {
        var box = await getBox(lazy);

        var stringList = List.filled(1000000, 'test');
        var doubleList = List.filled(1000000, 1.212312);
        var byteList = Uint8List.fromList(List.filled(1000000, 123));

        for (var i = 0; i < 5; i++) {
          await box.put('stringList$i', stringList);
          await box.put('doubleList$i', doubleList);
          await box.put('byteList$i', byteList);
        }

        box = await reopenBox(box);
        for (var i = 0; i < 5; i++) {
          var readStringList = await box.get('stringList$i');
          var readDoubleList = await box.get('doubleList$i');
          var readByteList = await box.get('byteList$i');

          expect(readStringList, stringList);
          expect(readDoubleList, doubleList);
          expect(readByteList, byteList);
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('put large strings', () {
      Future performTest(bool lazy) async {
        var box = await getBox(lazy);
        for (var i = 0; i < 5; i++) {
          var largeString = i.toString() * 1000000;
          await box.put('string$i', largeString);
        }

        box = await reopenBox(box);
        for (var i = 0; i < 5; i++) {
          var largeString = await box.get('string$i');

          expect(largeString == i.toString() * 1000000, true);
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('put many entries', () {
      Future performTest(bool lazy) async {
        var amount = isBrowser ? 1000 : 20000;
        var box = await getBox(lazy);
        for (var i = 0; i < amount; i++) {
          await box.put('string$i', 'test');
          await box.put('int$i', -i);
          await box.put('bool$i', i % 2 == 0);
        }

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          expect(await box.get('string$i'), 'test');
          expect(await box.get('int$i'), -i);
          expect(await box.get('bool$i'), i % 2 == 0);
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('put many entries with the same key', () {
      Future performTest(bool lazy) async {
        var amount = isBrowser ? 5 : 100;
        var box = await getBox(lazy);
        for (var i = 0; i < amount; i++) {
          for (var n = 0; n < 100; n++) {
            await box.put('string$i', 'test$n');
            await box.put('int$i', n);
            await box.put('bool$i', n % 2 == 0);
          }
        }

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          expect(await box.get('string$i'), 'test99');
          expect(await box.get('int$i'), 99);
          expect(await box.get('bool$i'), false);
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });
  }, timeout: longTimeout);
}
