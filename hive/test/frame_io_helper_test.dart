void main() {}

/*@TestOn('vm')

import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'frames.dart';

Uint8List _getBytes(List<Uint8List> list) {
  var builder = BytesBuilder();
  for (var b in list) {
    builder.add(b);
  }
  return builder.toBytes();
}

class _FrameIoHelperTest extends FrameIoHelper {
  final Uint8List bytes;

  _FrameIoHelperTest(this.bytes);

  @override
  Future<RandomAccessFile> openFile(String path) async {
    return getTempRaf(bytes);
  }

  @override
  Future<Uint8List> readFile(String path) async {
    return bytes;
  }
}

void main() {
  group('FrameIoHelper', () {
    group('.keysFromFile()', () {
      test('frame', () async {
        var keystore = Keystore.debug();
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytes));
        var recoveryOffset = await ioHelper.keysFromFile(null, keystore, null);
        expect(recoveryOffset, -1);

        var testKeystore = Keystore.debug();
        var offset = 0;
        var i = 0;
        for (var frame in testFrames) {
          var length = frameBytes[i++].length;
          testKeystore
              .insert(Frame.lazy(frame.key, length: length, offset: offset));
          offset += length;
        }

        expect(keystore.frames, testKeystore.frames);
      });

      test('encrypted', () async {
        var frames = <Frame>[];
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytesEncrypted));
        var recoveryOffset =
            await ioHelper.keysFromFile(null, frames, testCrypto);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          expect(
              frames[i],
              lazyFrameWithLength(
                  testFrames[i], frameBytesEncrypted[i].length));
        }
      });

      test('returns offset if problem occurs', () async {});
    });

    group('.allFromFile()', () {
      test('frame', () async {
        var frames = <Frame>[];
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytes));
        var recoveryOffset =
            await ioHelper.framesFromFile(null, frames, testRegistry, null);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          expect(
              frames[i], frameWithLength(testFrames[i], frameBytes[i].length));
        }
      });

      test('encrypted', () async {
        var frames = <Frame>[];
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytesEncrypted));
        var recoveryOffset = await ioHelper.framesFromFile(
            null, frames, testRegistry, testCrypto);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          expect(frames[i],
              frameWithLength(testFrames[i], frameBytesEncrypted[i].length));
        }
      });

      test('returns offset if problem occurs', () async {});
    });
  });
}
*/
