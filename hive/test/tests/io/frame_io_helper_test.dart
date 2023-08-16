@TestOn('vm')
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../frames.dart';

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
  Future<RandomAccessFile> overridableRAF(RandomAccessFile raf) async {
    return getTempRaf(bytes);
  }

  @override
  Future<Uint8List> overridableReadFile(RandomAccessFile raf) async {
    return bytes;
  }
}

void main() {
  group('FrameIoHelper', () {
    group('.keysFromFile()', () {
      test('frame', () async {
        var keystore = Keystore.debug();
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytes));
        var recoveryOffset = await ioHelper.keysFromFile(
            await getTempRaf(const []), keystore, null);
        expect(recoveryOffset, -1);

        var testKeystore = Keystore.debug(
          frames: lazyFrames(framesSetLengthOffset(testFrames, frameBytes)),
        );

        expectFrames(keystore.frames, testKeystore.frames);
      });

      test('encrypted', () async {
        var keystore = Keystore.debug();
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytesEncrypted));
        var recoveryOffset = await ioHelper.keysFromFile(
            await getTempRaf(const []), keystore, testCipher);
        expect(recoveryOffset, -1);

        var testKeystore = Keystore.debug(
          frames: lazyFrames(
            framesSetLengthOffset(testFrames, frameBytesEncrypted),
          ),
        );

        expectFrames(keystore.frames, testKeystore.frames);
      });

      test('returns offset if problem occurs', () async {});
    });

    group('.allFromFile()', () {
      test('frame', () async {
        var keystore = Keystore.debug();
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytes));
        var recoveryOffset = await ioHelper.framesFromFile(
            await getTempRaf(const []), keystore, testRegistry, null);
        expect(recoveryOffset, -1);

        var testKeystore = Keystore.debug(
          frames: framesSetLengthOffset(testFrames, frameBytes),
        );

        expectFrames(keystore.frames, testKeystore.frames);
      });

      test('encrypted', () async {
        var keystore = Keystore.debug();
        var ioHelper = _FrameIoHelperTest(_getBytes(frameBytesEncrypted));
        var recoveryOffset = await ioHelper.framesFromFile(
            await getTempRaf(const []), keystore, testRegistry, testCipher);
        expect(recoveryOffset, -1);

        var testKeystore = Keystore.debug(
          frames: framesSetLengthOffset(testFrames, frameBytesEncrypted),
        );

        expectFrames(keystore.frames, testKeystore.frames);
      });

      test('returns offset if problem occurs', () async {});
    });
  });
}
