import 'package:hive/src/binary/frame.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('Frame', () {
    group('constructors verifies', () {
      test('int keys', () {
        Frame(0, null);
        Frame.lazy(0);
        Frame.deleted(0);

        Frame(4294967295, null);
        Frame.lazy(4294967295);
        Frame.deleted(4294967295);

        expect(() => Frame(-1, null), throwsHiveException());
        expect(() => Frame.lazy(-1), throwsHiveException());
        expect(() => Frame.deleted(-1), throwsHiveException());

        expect(() => Frame(4294967296, null), throwsHiveException());
        expect(() => Frame.lazy(4294967296), throwsHiveException());
        expect(() => Frame.deleted(4294967296), throwsHiveException());
      });

      test('string keys', () {
        Frame('', null);
        Frame.lazy('');
        Frame.deleted('');

        Frame('a' * 255, null);
        Frame.lazy('a' * 255);
        Frame.deleted('a' * 255);

        expect(() => Frame('hellö', null), throwsHiveException());
        expect(() => Frame.lazy('hellö'), throwsHiveException());
        expect(() => Frame.deleted('hellö'), throwsHiveException());

        expect(() => Frame('a' * 256, null), throwsHiveException());
        expect(() => Frame.lazy('a' * 256), throwsHiveException());
        expect(() => Frame.deleted('a' * 256), throwsHiveException());
      });
    });

    test('.toString()', () {
      expect(Frame('key', 'val', offset: 1, length: 2).toString(),
          'Frame(key: key, value: val, length: 2, offset: 1)');
      expect(Frame.lazy('key', offset: 1, length: 2).toString(),
          'Frame.lazy(key: key, length: 2, offset: 1)');
      expect(Frame.deleted('key', length: 2).toString(),
          'Frame.deleted(key: key, length: 2)');
    });
  });
}
