import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

HiveObject _getHiveObject(String key, BoxMock box) {
  var hiveObject = HiveObjectMock();
  when(hiveObject.box).thenReturn(box);
  when(hiveObject.key).thenReturn(key);
  when(box.get(key)).thenReturn(hiveObject);
  return hiveObject;
}

void main() {
  group('HiveList', () {
    group('.box', () {
      test('throws HiveError if box is not open', () {
        var hive = HiveImpl();
        var hiveList = HiveList.debug('someBox', [], hive);
        expect(() => hiveList.box, throwsHiveError('you have to open the box'));
      });

      test('returns the box', () async {
        var hive = HiveImpl();
        var box = await hive.openBoxFromBytes('someBox', Uint8List(0));
        var hiveList = HiveList.debug('someBox', [], hive);
        expect(hiveList.box, box);
      });
    });

    test('.delegate', () {
      var hiveObject = HiveObjectMock();
      var box = BoxMock();
      when(box.get('key1')).thenReturn(hiveObject);

      when(hiveObject.key).thenReturn('key1');
      when(hiveObject.box).thenReturn(box);

      var hive = HiveMock();
      when(hive.getBoxInternal(any)).thenReturn(box);

      var hiveList =
          HiveList.debug('someBox', ['key1', 'nonExistingKey'], hive);

      expect(hiveList.delegate, [hiveObject]);
      verify(hive.getBoxInternal('someBox'));
    });

    group('operator []=', () {
      test('sets key at index', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key1']);

        var obj2 = _getHiveObject('key2', box);
        hiveList[0] = obj2;
        expect(hiveList.debugKeys, ['key2']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj2 = _getHiveObject('key2', BoxMock());
        expect(() => hiveList[0] = obj2, throwsHiveError());
      });
    });

    group('.add()', () {
      test('adds key', () {
        var box = BoxMock();
        var hiveList = HiveList(box);

        var obj1 = _getHiveObject('key1', box);
        hiveList.add(obj1);
        expect(hiveList.debugKeys, ['key1']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock());

        var obj2 = _getHiveObject('key2', BoxMock());
        expect(() => hiveList.add(obj2), throwsHiveError());
      });
    });

    group('.addAll()', () {
      test('adds keys', () {
        var box = BoxMock();
        var hiveList = HiveList(box);

        var obj1 = _getHiveObject('key1', box);
        var obj2 = _getHiveObject('key2', box);
        hiveList.addAll([obj1, obj2, obj1]);
        expect(hiveList.debugKeys, ['key1', 'key2', 'key1']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock());

        var obj = _getHiveObject('key', BoxMock());
        expect(() => hiveList.addAll([obj, obj]), throwsHiveError());
      });
    });

    test('.clear()', () {
      var box = BoxMock();
      var hiveList = HiveList(box, keys: ['key1', 'key2']);

      hiveList.clear();
      expect(hiveList.debugKeys, []);
    });

    group('.fillRange()', () {
      test('replaces range with obj', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key1', 'key1', 'key1', 'key1']);

        var obj2 = _getHiveObject('key2', box);
        hiveList.fillRange(1, 3, obj2);
        expect(hiveList.debugKeys, ['key1', 'key2', 'key2', 'key1']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj2 = _getHiveObject('key2', BoxMock());
        expect(() => hiveList.fillRange(0, 1, obj2), throwsHiveError());
      });
    });

    group('set first', () {
      test('replaces first key', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key2', 'key2']);

        var obj = _getHiveObject('key1', box);
        hiveList.first = obj;
        expect(hiveList.debugKeys, ['key1', 'key2']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj = _getHiveObject('key2', BoxMock());
        expect(() => hiveList.first = obj, throwsHiveError());
      });
    });

    group('.insert()', () {
      test('inserts key at index', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key2', 'key2']);

        var obj = _getHiveObject('key1', box);
        hiveList.insert(1, obj);
        expect(hiveList.debugKeys, ['key2', 'key1', 'key2']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj = _getHiveObject('key2', BoxMock());
        expect(() => hiveList.insert(0, obj), throwsHiveError());
      });
    });

    group('.insertAll()', () {
      test('inserts key at index', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key2', 'key2']);

        var obj = _getHiveObject('key1', box);
        hiveList.insertAll(1, [obj, obj]);
        expect(hiveList.debugKeys, ['key2', 'key1', 'key1', 'key2']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj = _getHiveObject('key2', BoxMock());
        expect(() => hiveList.insertAll(0, [obj]), throwsHiveError());
      });
    });

    group('set last', () {
      test('replaces first key', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key2', 'key2']);

        var obj = _getHiveObject('key1', box);
        hiveList.last = obj;
        expect(hiveList.debugKeys, ['key2', 'key1']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj = _getHiveObject('key2', BoxMock());
        expect(() => hiveList.last = obj, throwsHiveError());
      });
    });

    test('set length', () {
      var box = BoxMock();
      var hiveList = HiveList(box);

      hiveList.length = 5;
      expect(hiveList.debugKeys.length, 5);
    });

    group('.remove()', () {
      test('removes first occurrence of obj', () {
        var box = BoxMock();
        var hiveList = HiveList(box, keys: ['key1', 'key2', 'key2']);

        var obj = _getHiveObject('key2', box);
        expect(hiveList.remove(obj), true);
        expect(hiveList.debugKeys, ['key1', 'key2']);
        expect(hiveList.remove('key1'), false);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);

        var obj = _getHiveObject('key1', BoxMock());
        expect(() => hiveList.remove(obj), throwsHiveError());
      });
    });

    test('.removeAt()', () {
      var obj = HiveObjectMock();
      var box = BoxMock();
      when(box.get('key')).thenReturn(obj);

      var hiveList = HiveList(box, keys: ['key2', 'key']);
      expect(hiveList.removeAt(1), obj);
      expect(hiveList.debugKeys, ['key2']);
    });

    test('.removeLast()', () {
      var obj = HiveObjectMock();
      var box = BoxMock();
      when(box.get('key')).thenReturn(obj);

      var hiveList = HiveList(box, keys: ['key2', 'key3', 'key']);
      expect(hiveList.removeLast(), obj);
      expect(hiveList.debugKeys, ['key2', 'key3']);
    });

    test('.removeRange()', () {
      var hiveList = HiveList.internal('someBox', ['key1', 'key2', 'key3']);
      hiveList.removeRange(0, 2);
      expect(hiveList.debugKeys, ['key3']);
    });

    test('.removeWhere()', () {
      var box = BoxMock();
      _getHiveObject('key1', box);
      var obj2 = _getHiveObject('key2', box);

      var hiveList = HiveList(box, keys: ['key1', 'key2', 'key1', 'key2']);
      hiveList.removeWhere((it) => it == obj2);
      expect(hiveList.debugKeys, ['key1', 'key1']);
    });

    group('.replaceRange()', () {
      test('replaces objects in range', () {
        var box = BoxMock();
        var obj1 = _getHiveObject('key1', box);
        var obj2 = _getHiveObject('key2', box);

        var hiveList = HiveList(box, keys: ['key3', 'key3', 'key3']);

        hiveList.replaceRange(0, 2, [obj1, obj2]);
        expect(hiveList.debugKeys, ['key1', 'key2', 'key3']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);
        expect(() => hiveList.replaceRange(0, 1, [HiveObjectMock()]),
            throwsHiveError());
      });
    });

    group('.retainWhere()', () {
      test('replaces objects in range', () {
        var box = BoxMock();
        _getHiveObject('key1', box);
        var obj2 = _getHiveObject('key2', box);

        var hiveList = HiveList(box, keys: ['key1', 'key2', 'key1', 'key2']);

        hiveList.retainWhere((e) => e == obj2);
        expect(hiveList.debugKeys, ['key2', 'key2', 'key2', 'key2']);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveList(BoxMock(), keys: ['key1']);
        expect(() => hiveList.retainWhere(0, 1, [HiveObjectMock()]),
            throwsHiveError());
      });
    });
  });
}
