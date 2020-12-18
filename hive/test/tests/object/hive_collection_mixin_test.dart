import 'package:hive/hive.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../mocks.dart';

HiveList _getTestList(Box box) {
  var obj1 = MockHiveObject();
  obj1.init('key1', box);
  var obj2 = MockHiveObject();
  obj2.init('key2', box);
  var obj3 = MockHiveObject();
  obj3.init('key3', box);

  return HiveList(box, objects: [obj1, obj2, obj3]);
}

void main() {
  group('HiveCollectionMixin', () {
    test('.keys', () {
      var box = MockBox();
      var hiveList = _getTestList(box);

      expect(hiveList.keys, ['key1', 'key2', 'key3']);
    });

    test('.deleteAllFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);

      hiveList.deleteAllFromHive();
      verify(box.deleteAll(['key1', 'key2', 'key3']));
    });

    test('.deleteFirstFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);

      hiveList.deleteFirstFromHive();
      verify(box.delete('key1'));
    });

    test('.deleteLastFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);

      hiveList.deleteLastFromHive();
      verify(box.delete('key3'));
    });

    test('.deleteFromFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);

      hiveList.deleteFromHive(1);
      verify(box.delete('key2'));
    });

    test('.toMap()', () {
      var box = MockBox();
      var obj1 = MockHiveObject();
      obj1.init('key1', box);
      var obj2 = MockHiveObject();
      obj2.init('key2', box);

      var hiveList = HiveList(box, objects: [obj1, obj2]);

      expect(hiveList.toMap(), {'key1': obj1, 'key2': obj2});
    });
  });
}
