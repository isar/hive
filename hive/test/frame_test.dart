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
          var bytes = frame.toBytes(testRegistry, null);
          expect(bytes, frameBytes[i]);
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(testRegistry, testCrypto);
          expect(bytes, frameBytesEncrypted[i]);
          i++;
        }
      });
    });

    group('.encodeValue()', () {
      test('values', () {
        var i = 0;
        for (var frame in testFrames) {
          var writer = BinaryWriterImpl(testRegistry);
          Frame.encodeValue(frame.value, writer, null);
          expect(writer.output(), frameValuesBytes[i]);
          i++;
        }
      });

      test('encrypted values', () {
        var i = 0;
        for (var frame in testFrames) {
          var writer = BinaryWriterImpl(testRegistry);
          Frame.encodeValue(frame.value, writer, testCrypto);
          expect(writer.output(), frameValuesBytesEncrypted[i]);
          i++;
        }
      });
    });

    group('.fromBytes()', () {
      test('frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var frame = Frame.fromBytes(frameBytes[i], testRegistry, null);
          fEqual(frame, frameWithLength(testFrame, frameBytes[i].length));
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesEncrypted[i];
          var frame = Frame.fromBytes(bytes, testRegistry, testCrypto);
          fEqual(frame, frameWithLength(testFrame, bytes.length));
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
