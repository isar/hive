import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:hive/src/object/hive_object.dart';

import '../common.dart';
import '../mocks.dart';

class _TestObject extends HiveObject {}

void main() {
  group('HiveObject', () {
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
