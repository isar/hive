import 'package:hive/hive.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../common.dart';
import '../mocks.dart';

HiveList _getTestList(MockBox box) {
  when(box.name).thenReturn('testBox');
  var obj1 = TestHiveObject();
  obj1.init('key1', box);
  var obj2 = TestHiveObject();
  obj2.init('key2', box);
  var obj3 = TestHiveObject();
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

    /// This test fails on sound null safety because [HiveCollectionMixin.keys]
    /// is an generator function, therefore every call results in an unique
    /// iterable, so without either the [all] matcher or allowing to return
    /// [Null] instead of [Future<void>] on [MockBox.deleteAll], this test is
    /// unfixable with the current implementation.
    test('.deleteAllFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);

      hiveList.deleteAllFromHive();
      verify(box.deleteAll(['key1', 'key2', 'key3']));
    }, skip: soundNullSafety ? "Can't pass with sound null safety" : false);

    test('.deleteFirstFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);
      returnFutureVoid(when(box.delete('key1')));

      hiveList.deleteFirstFromHive();
      verify(box.delete('key1'));
    });

    test('.deleteLastFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);
      returnFutureVoid(when(box.delete('key3')));

      hiveList.deleteLastFromHive();
      verify(box.delete('key3'));
    });

    test('.deleteFromHive()', () {
      var box = MockBox();
      var hiveList = _getTestList(box);
      returnFutureVoid(when(box.delete('key2')));

      hiveList.deleteFromHive(1);
      verify(box.delete('key2'));
    });

    test('.toMap()', () {
      var box = MockBox();
      when(box.name).thenReturn('testBox');
      var obj1 = TestHiveObject();
      obj1.init('key1', box);
      var obj2 = TestHiveObject();
      obj2.init('key2', box);

      var hiveList = HiveList(box, objects: [obj1, obj2]);

      expect(hiveList.toMap(), {'key1': obj1, 'key2': obj2});
    });
  });
}
