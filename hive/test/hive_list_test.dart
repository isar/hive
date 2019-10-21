import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import 'common.dart';

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
  });
}
