import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:test/test.dart';

import 'frames.dart';

void main() {
  group('Frame', () {
    group('.toBytes()', () {
      test('frames', () {
        var i = 0;
        for (var frame in testFrames) {
          var writer = BinaryWriterImpl(testRegistry);
          var count = frame.toBytes(writer, null);
          expect(writer.toBytes(), frameBytes[i]);
          expect(count, frameBytes[i].length);
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var frame in testFrames) {
          var writer = BinaryWriterImpl(testRegistry);
          var count = frame.toBytes(writer, testCrypto);
          expect(writer.toBytes(), frameBytesEncrypted[i]);
          expect(count, frameBytesEncrypted[i].length);
          i++;
        }
      });
    });

    group('.encodeValue()', () {
      test('values', () {
        var i = 0;
        for (var frame in testFrames) {
          var writer = BinaryWriterImpl(testRegistry);
          frame.encodeValue(writer, null);
          expect(writer.toBytes(), frameValuesBytes[i]);
          i++;
        }
      });

      test('encrypted values', () {
        var i = 0;
        for (var frame in testFrames) {
          var writer = BinaryWriterImpl(testRegistry);
          frame.encodeValue(writer, testCrypto);
          expect(writer.toBytes(), frameValuesBytesEncrypted[i]);
          i++;
        }
      });
    });

    group('.fromBytes()', () {
      test('frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var reader = BinaryReaderImpl(frameBytes[i], testRegistry);
          var frame = Frame.fromBytes(reader, null);
          fEqual(frame, frameWithLength(testFrame, frameBytes[i].length));
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var reader = BinaryReaderImpl(frameBytesEncrypted[i], testRegistry);
          var frame = Frame.fromBytes(reader, testCrypto);
          fEqual(
              frame, frameWithLength(testFrame, frameBytesEncrypted[i].length));
          i++;
        }
      });
    });

    group('.decodeValue()', () {
      test('values', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var reader = BinaryReaderImpl(frameValuesBytes[i], testRegistry);
          var value = Frame.decodeValue(reader, null);
          expect(value, testFrame.value);
          i++;
        }
      });

      test('encrypted values', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var reader =
              BinaryReaderImpl(frameValuesBytesEncrypted[i], testRegistry);
          var value = Frame.decodeValue(reader, testCrypto);
          expect(value, testFrame.value);
          i++;
        }
      });
    });
  });
}
