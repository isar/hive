import 'package:hive/src/binary/frame.dart';
import 'package:test/test.dart';

import 'frames.dart';

void main() {
  test('b', buildGoldens);

  group('Frame', () {
    group('.toBytes()', () {
      test('validates key length', () async {
        var tooLongKey = List.filled(256, 'a').join();
        var tooLongFrame = Frame(tooLongKey, 5);
        expect(
          () => tooLongFrame.toBytes(true, registry, null),
          throwsA(anything),
        );

        var validKey = List.filled(255, 'a').join();
        var frame = Frame(validKey, 5);
        frame.toBytes(true, registry, null);
      });

      test('frames', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(true, registry, null);
          expect(bytes, frameBytes[i]);
          i++;
        }
      });

      test('frames body only', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(false, registry, null);
          expect(bytes, frameBytesBodyOnly[i]);
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(true, registry, getDebugCrypto());
          expect(bytes, frameBytesEncrypted[i]);
          i++;
        }
      });

      test('encrypted frames body only', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(false, registry, getDebugCrypto());
          expect(bytes, frameBytesEncryptedBodyOnly[i]);
          i++;
        }
      });
    });

    group('.fromBytes()', () {
      test('frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var frame = Frame.fromBytes(frameBytes[i], registry, null);
          fEqual(frame, frameWithLength(testFrame, frameBytes[i].length));
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesEncrypted[i];
          var frame = Frame.fromBytes(bytes, registry, getDebugCrypto());
          fEqual(frame, frameWithLength(testFrame, bytes.length));
          i++;
        }
      });
    });

    group('.bodyFromBytes()', () {
      test('frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesBodyOnly[i];
          var frame = Frame.bodyFromBytes(bytes, registry, null);
          fEqual(frame, frameBodyWithLength(testFrame, bytes.length));
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesEncryptedBodyOnly[i];
          var frame = Frame.bodyFromBytes(bytes, registry, getDebugCrypto());
          fEqual(frame, frameBodyWithLength(testFrame, bytes.length));
          i++;
        }
      });
    });
  });
}
