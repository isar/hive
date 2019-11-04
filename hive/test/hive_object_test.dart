import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

class _TestObject extends HiveObject {}

void main() {
  group('HiveObject', () {
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

        var list1 = obj1.backlink();
        list1.addAll([obj2, obj3, obj2]);
        obj2.unload();

        expect(list1, [obj3]);
      });
    });

    group('.save()', () {
      test('updates object in box', () {
        var obj = _TestObject();
        var box = BoxMock();
        obj.init('key', box);
        verifyZeroInteractions(box);

        obj.save();
        verify(box.put('key', obj));
      });

      test('throws HiveError if object is not in a box', () async {
        var obj = _TestObject();
        await expectLater(() => obj.save(), throwsHiveError('not in a box'));
      });
    });

    group('.delete()', () {
      test('removes object from box', () {
        var obj = _TestObject();
        var box = BoxMock();
        obj.init('key', box);
        verifyZeroInteractions(box);

        obj.delete();
        verify(box.delete('key'));
      });

      test('throws HiveError if object is not in a box', () async {
        var obj = _TestObject();
        await expectLater(() => obj.delete(), throwsHiveError('not in a box'));
      });
    });

    group('.isInBox', () {
      test('returns false if box is not set', () {
        var obj = _TestObject();
        expect(obj.isInBox, false);
      });

      test('returns true if object is in normal box', () {
        var obj = _TestObject();
        var box = BoxMock();
        when(box.lazy).thenReturn(false);
        obj.init('key', box);

        expect(obj.isInBox, true);
      });

      test('returns the result ob box.containsKey() if object is in lazy box',
          () {
        var obj = _TestObject();
        var box = BoxMock();
        when(box.lazy).thenReturn(true);
        obj.init('key', box);

        when(box.containsKey('key')).thenReturn(true);
        expect(obj.isInBox, true);

        when(box.containsKey('key')).thenReturn(false);
        expect(obj.isInBox, false);
      });
    });
  });
}
