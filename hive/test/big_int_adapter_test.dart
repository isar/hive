import 'dart:typed_data';

import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:test/test.dart';

void main() {
  group('BigIntAdapter', () {
    group('.read()', () {
      test('positive', () {
        var numberStr = '123456789123456789';
        var bytes =
            Uint8List.fromList([numberStr.length, ...numberStr.codeUnits]);
        var reader = BinaryReaderImpl(bytes, null);
        expect(BigIntAdapter().read(reader), BigInt.parse(numberStr));
      });

      test('negative', () {
        var numberStr = '-123456789123456789';
        var bytes =
            Uint8List.fromList([numberStr.length, ...numberStr.codeUnits]);
        var reader = BinaryReaderImpl(bytes, null);
        expect(BigIntAdapter().read(reader), BigInt.parse(numberStr));
      });
    });

    test('write', () {
      var numberStr = '123456789123456789';
      var writer = BinaryWriterImpl(null);
      BigIntAdapter().write(writer, BigInt.parse(numberStr));
      expect(writer.toBytes(), [numberStr.length, ...numberStr.codeUnits]);
    });
  });
}
