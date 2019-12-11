import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:hive/src/object/hive_object.dart';

import '../common.dart';
import '../mocks.dart';

class _TestObject extends HiveObject {}

void main() {
  group('HiveObjectInternal', () {
    group('.init()', () {
      test('adds key and box to HiveObject', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('someKey', box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('does nothing if old key and box are equal to new key and box', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('someKey', box);
        obj.init('someKey', box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('throws exception if object is already in a different box', () {
        var obj = _TestObject();
        var box1 = BoxMock();
        var box2 = BoxMock();

        obj.init('someKey', box1);
        expect(() => obj.init('someKey', box2),
            throwsHiveError('two different boxes'));
      });

      test('throws exception if object has already different key', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('key1', box);
        expect(
            () => obj.init('key2', box), throwsHiveError('two different keys'));
      });
    });

    group('.unload()', () {
      test('removes key and box', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('key', box);
        obj.unload();

        expect(obj.key, null);
        expect(obj.box, null);
      });

      test('notifies remote HiveLists', () {
        var obj = _TestObject();
        var list1 = HiveListMock();
        var list2 = HiveListMock();
        var box = BoxMock();

        obj.init('key', box);
        obj.linkRemoteHiveList(list1);
        obj.linkRemoteHiveList(list2);
        obj.unload();

        verify(list1.notifyRemoveObject(obj));
        verify(list2.notifyRemoveObject(obj));
      });

      test('disposes HiveLists', () {
        var obj1 = _TestObject();
        var obj2 = _TestObject();
        var obj3 = _TestObject();
        var box = BoxMock();

        obj1.init('key1', box);
        obj2.init('key2', box);
        obj3.init('key3', box);

        var list1 = obj1.backlink(box);
        list1.addAll([obj2, obj3, obj2]);
        obj2.unload();

        expect(list1, [obj3]);
      });
    });

    test('.linkRemoteHiveList()', () {
      var box = BoxMock();
      var obj = _TestObject();
      obj.init('key', box);
      var hiveList = HiveListMock();

      obj.linkRemoteHiveList(hiveList);
      expect(obj.debugRemoteHiveLists, {hiveList: 1});
      obj.linkRemoteHiveList(hiveList);
      expect(obj.debugRemoteHiveLists, {hiveList: 2});
    });

    test('.unlinkRemoteHiveList()', () {
      var box = BoxMock();
      var obj = _TestObject();
      obj.init('key', box);
      var hiveList = HiveListMock();

      obj.linkRemoteHiveList(hiveList);
      obj.linkRemoteHiveList(hiveList);
      expect(obj.debugRemoteHiveLists, {hiveList: 2});

      obj.unlinkRemoteHiveList(hiveList);
      expect(obj.debugRemoteHiveLists, {hiveList: 1});
      obj.unlinkRemoteHiveList(hiveList);
      expect(obj.debugRemoteHiveLists, {});
    });
  });
}
