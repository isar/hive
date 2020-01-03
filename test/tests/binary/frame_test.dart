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

        expect(() => Frame(-1, null), throwsHiveError());
        expect(() => Frame.lazy(-1), throwsHiveError());
        expect(() => Frame.deleted(-1), throwsHiveError());

        expect(() => Frame(4294967296, null), throwsHiveError());
        expect(() => Frame.lazy(4294967296), throwsHiveError());
        expect(() => Frame.deleted(4294967296), throwsHiveError());
      });

      test('string keys', () {
        Frame('', null);
        Frame.lazy('');
        Frame.deleted('');

        Frame('a' * 255, null);
        Frame.lazy('a' * 255);
        Frame.deleted('a' * 255);

        expect(() => Frame('hellö', null), throwsHiveError());
        expect(() => Frame.lazy('hellö'), throwsHiveError());
        expect(() => Frame.deleted('hellö'), throwsHiveError());

        expect(() => Frame('a' * 256, null), throwsHiveError());
        expect(() => Frame.lazy('a' * 256), throwsHiveError());
        expect(() => Frame.deleted('a' * 256), throwsHiveError());
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
