import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:hive/src/object/hive_object.dart';

import '../common.dart';
import '../mocks.dart';

HiveObjectMock _getHiveObject(String key, BoxMock box) {
  var hiveObject = HiveObjectMock();
  when(hiveObject.box).thenReturn(box);
  when(hiveObject.key).thenReturn(key);
  when(box.get(key, defaultValue: argThat(isNotNull, named: 'defaultValue')))
      .thenReturn(hiveObject);
  return hiveObject;
}

void main() {
  group('HiveListImpl', () {
    group('.box', () {
      test('throws HiveError if box is not open', () {
        var hive = HiveImpl();
        var hiveList = HiveListImpl.debug('someBox', [], hive);
        expect(() => hiveList.box, throwsHiveError('box not found'));
      });

      test('returns the box', () async {
        var hive = HiveImpl();
        var box = await hive.openBox('someBox', bytes: Uint8List(0));
        var hiveList = HiveListImpl.debug('someBox', [], hive);
        expect(hiveList.box, box);
      });
    });

    test('.delegate', () {
      var box = BoxMock();
      when(box.get(any, defaultValue: anyNamed('defaultValue')))
          .thenAnswer((i) => i.namedArguments[#defaultValue]);
      var obj1 = _getHiveObject('key1', box);
      var obj2 = _getHiveObject('key2', box);

      var hive = HiveMock();
      when(hive.getBoxInternal(any)).thenReturn(box);

      var hiveList = HiveListImpl.debug(
          'someBox', ['key1', 'nonExistingKey', 'key2'], hive);

      expect(hiveList.delegate, [obj1, obj2]);
    });

    test('.notifyRemoveObject()', () {
      var box = BoxMock();
      var obj1 = _getHiveObject('key1', box);
      var obj2 = _getHiveObject('key2', box);
      var hiveList = HiveListImpl(box, objects: [obj1, obj2, obj1]);

      hiveList.notifyRemoveObject(obj1);

      expect(hiveList, [obj2]);
    });

    test('.dispose()', () {
      var box = BoxMock();
      var obj1 = _getHiveObject('key1', box);
      var obj2 = _getHiveObject('key2', box);
      var hiveList = HiveListImpl(box, objects: [obj1, obj2, obj1]);

      hiveList.dispose();

      verifyInOrder([
        obj1.unlinkRemoteHiveList(hiveList),
        obj2.unlinkRemoteHiveList(hiveList),
        obj1.unlinkRemoteHiveList(hiveList),
      ]);

      expect(() => hiveList.delegate, throwsA(anything));
    });

    group('operator []=', () {
      test('sets key at index', () {
        var box = BoxMock();
        var obj1 = _getHiveObject('old', box);
        var hiveList = HiveListImpl(box, objects: [obj1]);

        var obj2 = _getHiveObject('new', box);
        hiveList[0] = obj2;

        verify(obj1.unlinkRemoteHiveList(hiveList));
        verify(obj2.linkRemoteHiveList(hiveList));
        expect(hiveList, [obj2]);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var obj1 = HiveObjectMock();
        var hiveList = HiveListImpl(BoxMock(), objects: <HiveObject>[obj1]);

        var obj2 = _getHiveObject('key2', BoxMock());
        expect(() => hiveList[0] = obj2, throwsHiveError());
      });
    });

    group('.add()', () {
      test('adds key', () {
        var box = BoxMock();
        var obj1 = HiveObjectMock();
        var hiveList = HiveListImpl(box, objects: [obj1]);

        var obj2 = _getHiveObject('key1', box);
        hiveList.add(obj2);

        verify(obj2.linkRemoteHiveList(hiveList));
        expect(hiveList, [obj1, obj2]);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveListImpl(BoxMock());

        var obj = _getHiveObject('key', BoxMock());
        expect(() => hiveList.add(obj), throwsHiveError());
      });
    });

    group('.addAll()', () {
      test('adds keys', () {
        var box = BoxMock();
        var obj1 = HiveObjectMock();
        var hiveList = HiveListImpl(box, objects: [obj1]);

        var obj2 = _getHiveObject('key1', box);
        var obj3 = _getHiveObject('key2', box);
        hiveList.addAll([obj2, obj3, obj2]);
        verifyInOrder([
          obj2.linkRemoteHiveList(hiveList),
          obj3.linkRemoteHiveList(hiveList),
          obj2.linkRemoteHiveList(hiveList),
        ]);
        expect(hiveList, [obj1, obj2, obj3, obj2]);
      });

      test('throws HiveError if HiveObject is not valid', () {
        var hiveList = HiveListImpl(BoxMock());

        var obj = _getHiveObject('key', BoxMock());
        expect(() => hiveList.addAll([obj, obj]), throwsHiveError());
      });
    });

    test('set length', () {
      var box = BoxMock();
      var obj1 = HiveObjectMock();
      var obj2 = HiveObjectMock();
      var obj3 = HiveObjectMock();
      var hiveList = HiveListImpl(box, objects: [obj1, obj2, obj3]);

      hiveList.length = 1;

      verify(obj2.unlinkRemoteHiveList(hiveList));
      verify(obj3.unlinkRemoteHiveList(hiveList));
      expect(hiveList, [obj1]);
    });
  });
}
