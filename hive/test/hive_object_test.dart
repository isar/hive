import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

class _TestObject extends HiveObject {}

void main() {
  group('HiveObject', () {
    group('initHiveObject()', () {
      test('adds key and box to HiveObject', () {
        var obj = _TestObject();
        var box = BoxMock();

        initHiveObject('someKey', obj, box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('does nothing if old key and box are equal to new key and box', () {
        var obj = _TestObject();
        var box = BoxMock();

        initHiveObject('someKey', obj, box);
        initHiveObject('someKey', obj, box);

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('throws exception if object is already in a different box', () {
        var obj = _TestObject();
        var box1 = BoxMock();
        var box2 = BoxMock();

        initHiveObject('someKey', obj, box1);
        expect(() => initHiveObject('someKey', obj, box2),
            throwsHiveError('two different boxes'));
      });

      test('throws exception if object has already different key', () {
        var obj = _TestObject();
        var box = BoxMock();

        initHiveObject('key1', obj, box);
        expect(() => initHiveObject('key2', obj, box),
            throwsHiveError('two different keys'));
      });
    });

    test('unloadHiveObject removes key and box', () {
      var obj = _TestObject();
      var box = BoxMock();

      initHiveObject('key', obj, box);
      unloadHiveObject(obj);

      expect(obj.key, null);
      expect(obj.box, null);
    });

    group('.save()', () {
      test('updates object in box', () {
        var obj = _TestObject();
        var box = BoxMock();
        initHiveObject('key', obj, box);
        verifyZeroInteractions(box);

        obj.save();
        verify(box.put('key', obj));
      });

      test('throws exception if object is not in a box', () {
        var obj = _TestObject();

        expect(() => obj.save(),
            throwsHiveError('add this object to a box first'));
      });
    });

    group('.delete()', () {
      test('removes object from box', () {
        var obj = _TestObject();
        var box = BoxMock();
        initHiveObject('key', obj, box);
        verifyZeroInteractions(box);

        obj.delete();
        verify(box.delete('key'));
      });

      test('does nothing if object is not in a box', () {
        var obj = _TestObject();
        obj.delete();
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
        initHiveObject('key', obj, box);

        expect(obj.isInBox, true);
      });

      test('returns the result ob box.containsKey() if object is in lazy box',
          () {
        var obj = _TestObject();
        var box = BoxMock();
        when(box.lazy).thenReturn(true);
        initHiveObject('key', obj, box);

        when(box.containsKey('key')).thenReturn(true);
        expect(obj.isInBox, true);

        when(box.containsKey('key')).thenReturn(false);
        expect(obj.isInBox, false);
      });
    });
  });
}
