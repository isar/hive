import 'package:hive/hive.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks.dart';

HiveList _getTestList(Box box) {
  var obj1 = TestHiveObject();
  obj1.init('key1', box);
  var obj2 = TestHiveObject();
  obj2.init('key2', box);
  var obj3 = TestHiveObject();
  obj3.init('key3', box);

  return HiveList(obj1, box, objects: [obj1, obj2, obj3]);
}

void main() {
  group('HiveCollectionMixin', () {
    test('.keys', () {
      var box = BoxMock();
      var hiveList = _getTestList(box);

      expect(hiveList.keys, ['key1', 'key2', 'key3']);
    });

    test('.deleteAllFromHive()', () {
      var box = BoxMock();
      var hiveList = _getTestList(box);

      hiveList.deleteAllFromHive();
      verify(box.deleteAll(['key1', 'key2', 'key3']));
    });

    test('.deleteFirstFromHive()', () {
      var box = BoxMock();
      var hiveList = _getTestList(box);

      hiveList.deleteFirstFromHive();
      verify(box.delete('key1'));
    });

    test('.deleteLastFromHive()', () {
      var box = BoxMock();
      var hiveList = _getTestList(box);

      hiveList.deleteLastFromHive();
      verify(box.delete('key3'));
    });

    test('.deleteFromFromHive()', () {
      var box = BoxMock();
      var hiveList = _getTestList(box);

      hiveList.deleteFromHive(1);
      verify(box.delete('key2'));
    });

    test('.toMap()', () {
      var box = BoxMock();
      var obj1 = TestHiveObject();
      obj1.init('key1', box);
      var obj2 = TestHiveObject();
      obj2.init('key2', box);

      var hiveList = HiveList(obj1, box, objects: [obj1, obj2]);

      expect(hiveList.toMap(), {'key1': obj1, 'key2': obj2});
    });
  });
}
