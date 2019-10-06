import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'frames.dart';
import 'util/is_browser.dart';

Future<Box> getBox(bool lazy) async {
  var hive = HiveImpl();
  if (!isBrowser) {
    var dir = await getTempDir();
    hive.init(dir.path);
  }
  return await hive.openBox('box', lazy: lazy, crashRecovery: false);
}

Future<Box> reopenBox(Box box) async {
  await box.close();
  var hive = (box as BoxBase).hive;
  return await hive.openBox('box', lazy: box.lazy, crashRecovery: false);
}

const longTimeout = Timeout(Duration(minutes: 2));

void main() {
  group('Integration test', () {
    group('put large lists', () {
      Future performTest(bool lazy) async {
        var box = await getBox(lazy);

        var stringList = List.filled(1000000, 'test', growable: true)
          ..add(null);
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
        var repeat = isBrowser ? 100 : 1000;
        var box = await getBox(lazy);
        for (var i = 0; i < repeat; i++) {
          for (var frame in valueTestFrames) {
            await box.put('${frame.key}n$i', frame.value);
          }
        }

        box = await reopenBox(box);
        for (var i = 0; i < repeat; i++) {
          for (var frame in valueTestFrames) {
            expect(await box.get('${frame.key}n$i'), frame.value);
          }
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
            await box.put('null$i', null);
          }
        }

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          expect(await box.get('string$i'), 'test99');
          expect(await box.get('int$i'), 99);
          expect(await box.get('bool$i'), false);
          expect(await box.get('null$i', defaultValue: 0), null);
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('put many entries in a single batch', () {
      Future performTest(bool lazy) async {
        var repeat = isBrowser ? 100 : 1000;
        var box = await getBox(lazy);
        var entries = <String, dynamic>{};
        for (var i = 0; i < repeat; i++) {
          for (var frame in valueTestFrames) {
            entries['${frame.key}n$i'] = frame.value;
          }
        }
        await box.putAll(entries);

        box = await reopenBox(box);
        for (var i = 0; i < repeat; i++) {
          for (var frame in valueTestFrames) {
            expect(await box.get('${frame.key}n$i'), frame.value);
          }
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('put many entries simultaneously', () {
      Future performTest(bool lazy) async {
        var amount = isBrowser ? 10 : 100;
        var box = await getBox(lazy);

        Future putEntries() async {
          for (var i = 0; i < amount; i++) {
            await box.put('key$i', 'value$i');
          }
        }

        var futures = <Future>[];
        for (var i = 0; i < 10; i++) {
          futures.add(putEntries());
        }
        await Future.wait(futures);

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          expect(await box.get('key$i'), 'value$i');
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('delete many entries', () {
      Future performTest(bool lazy) async {
        var amount = isBrowser ? 1000 : 20000;
        var box = await getBox(lazy);
        var entries = <String, dynamic>{};
        for (var i = 0; i < amount; i++) {
          entries['string$i'] = 'test';
          entries['int$i'] = -i;
          entries['bool$i'] = i % 2 == 0;
          entries['null$i'] = null;
        }
        await box.putAll(entries);
        await box.put('123123', 'value');

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          await box.delete('string$i');
          await box.delete('int$i');
          await box.delete('bool$i');
          await box.delete('null$i');
        }

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          expect(box.containsKey('string$i'), false);
          expect(box.containsKey('int$i'), false);
          expect(box.containsKey('bool$i'), false);
          expect(box.containsKey('null$i'), false);
        }
        expect(await box.get('123123'), 'value');
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('delete many entries in a single batch', () {
      Future performTest(bool lazy) async {
        var amount = isBrowser ? 1000 : 20000;
        var box = await getBox(lazy);
        var entries = <String, dynamic>{};
        for (var i = 0; i < amount; i++) {
          entries['string$i'] = 'test';
          entries['int$i'] = -i;
          entries['bool$i'] = i % 2 == 0;
          entries['null$i'] = null;
        }
        await box.putAll(entries);
        await box.put('123123', 'value');

        box = await reopenBox(box);
        await box.deleteAll(entries.keys);

        box = await reopenBox(box);
        for (var i = 0; i < amount; i++) {
          expect(box.containsKey('string$i'), false);
          expect(box.containsKey('int$i'), false);
          expect(box.containsKey('bool$i'), false);
          expect(box.containsKey('null$i'), false);
        }
        expect(await box.get('123123'), 'value');
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });

    group('different frame types', () {
      Future performTest(bool lazy) async {
        var box = await getBox(lazy);
        for (var frame in valueTestFrames) {
          if (frame.deleted) continue;
          await box.put(frame.key, frame.value);
        }

        box = await reopenBox(box);

        for (var frame in valueTestFrames) {
          if (frame.deleted) continue;
          var f = await box.get(frame.key);
          expect(f, frame.value);
        }
        await box.close();
      }

      test('normal box', () async => performTest(false));

      test('lazy box', () async => performTest(true));
    });
  }, timeout: longTimeout);
}
