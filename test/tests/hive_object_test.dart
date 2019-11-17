import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'mocks.dart';

class _TestObject extends HiveObject {}

void main() {
  group('HiveObject', () {
    group('.init()', () {
      test('adds key and box to HiveObject', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('someKey', box); // ignore: invalid_use_of_protected_member

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('does nothing if old key and box are equal to new key and box', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('someKey', box); // ignore: invalid_use_of_protected_member
        obj.init('someKey', box); // ignore: invalid_use_of_protected_member

        expect(obj.key, 'someKey');
        expect(obj.box, box);
      });

      test('throws exception if object is already in a different box', () {
        var obj = _TestObject();
        var box1 = BoxMock();
        var box2 = BoxMock();

        obj.init('someKey', box1); // ignore: invalid_use_of_protected_member
        expect(
            // ignore: invalid_use_of_protected_member
            () => obj.init('someKey', box2),
            throwsHiveError('two different boxes'));
      });

      test('throws exception if object has already different key', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('key1', box); // ignore: invalid_use_of_protected_member
        expect(
          // ignore: invalid_use_of_protected_member
          () => obj.init('key2', box),
          throwsHiveError('two different keys'),
        );
      });
    });

    group('.unload()', () {
      test('removes key and box', () {
        var obj = _TestObject();
        var box = BoxMock();

        obj.init('key', box); // ignore: invalid_use_of_protected_member
        obj.unload(); // ignore: invalid_use_of_protected_member

        expect(obj.key, null);
        expect(obj.box, null);
      });

      group('.save()', () {
        test('updates object in box', () {
          var obj = _TestObject();
          var box = BoxMock();
          obj.init('key', box); // ignore: invalid_use_of_protected_member
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
          obj.init('key', box); // ignore: invalid_use_of_protected_member
          verifyZeroInteractions(box);

          obj.delete();
          verify(box.delete('key'));
        });

        test('throws HiveError if object is not in a box', () async {
          var obj = _TestObject();
          await expectLater(
              () => obj.delete(), throwsHiveError('not in a box'));
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
          obj.init('key', box); // ignore: invalid_use_of_protected_member

          expect(obj.isInBox, true);
        });

        test('returns the result ob box.containsKey() if object is in lazy box',
            () {
          var obj = _TestObject();
          var box = BoxMock();
          when(box.lazy).thenReturn(true);
          obj.init('key', box); // ignore: invalid_use_of_protected_member

          when(box.containsKey('key')).thenReturn(true);
          expect(obj.isInBox, true);

          when(box.containsKey('key')).thenReturn(false);
          expect(obj.isInBox, false);
        });
      });
    });
  });
}
