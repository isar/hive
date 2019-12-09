import 'package:hive/src/binary/frame.dart';
import 'package:test/test.dart';

void main() {
  group('Frame', () {
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
