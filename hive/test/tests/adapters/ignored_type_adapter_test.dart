import 'package:hive/src/adapters/ignored_type_adapter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('IgnoredTypeAdapter', () {
    test('.read()', () {
      var binaryReader = BinaryReaderMock();
      var value = IgnoredTypeAdapter().read(binaryReader);
      verifyNever(binaryReader.read());
      expect(value, null);
    });

    test('.write()', () {
      var binaryWriter = BinaryWriterMock();
      IgnoredTypeAdapter().write(binaryWriter, 42);
      verifyNever(binaryWriter.writeInt(42));
    });
  });
}
