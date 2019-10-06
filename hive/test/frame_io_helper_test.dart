@TestOn('vm')

import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:test/test.dart';

import 'buffered_file_reader_test.dart';
import 'frames.dart';

Uint8List getBytes(List<Uint8List> list) {
  var builder = BytesBuilder();
  for (var b in list) {
    builder.add(b);
  }
  return builder.toBytes();
}

class FrameIoHelperTest extends FrameIoHelper {
  final Uint8List bytes;

  FrameIoHelperTest(this.bytes);

  @override
  Future<RandomAccessFile> openFile(String path) async {
    return getRafMock(bytes);
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
        var frames = <Frame>[];
        var ioHelper = FrameIoHelperTest(getBytes(frameBytes));
        var recoveryOffset = await ioHelper.keysFromFile(null, frames, null);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          fEqual(frames[i],
              lazyFrameWithLength(testFrames[i], frameBytes[i].length));
        }
      });

      test('encrypted', () async {
        var frames = <Frame>[];
        var ioHelper = FrameIoHelperTest(getBytes(frameBytesEncrypted));
        var recoveryOffset =
            await ioHelper.keysFromFile(null, frames, testCrypto);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          fEqual(
              frames[i],
              lazyFrameWithLength(
                  testFrames[i], frameBytesEncrypted[i].length));
        }
      });

      test('returns offset if problem occurs', () async {
        for (var n = 0; n < frameBytes.length; n++) {
          var frame = frameBytes[n];
          var bytesBefore = getBytes(frameBytes.sublist(0, n));
          for (var i = 1; i < frame.length - 1; i++) {
            var bytes = bytesBefore + frame.sublist(0, i);
            var ioHelper = FrameIoHelperTest(Uint8List.fromList(bytes));
            var frames = <Frame>[];
            var recoveryOffset =
                await ioHelper.keysFromFile(null, frames, null);
            expect(recoveryOffset, bytesBefore.length);

            var framesBefore = testFrames.sublist(0, n);
            for (var i = 0; i < framesBefore.length; i++) {
              fEqual(frames[i],
                  lazyFrameWithLength(framesBefore[i], frameBytes[i].length));
            }
          }
        }
      });
    });

    group('.allFromFile()', () {
      test('frame', () async {
        var frames = <Frame>[];
        var ioHelper = FrameIoHelperTest(getBytes(frameBytes));
        var recoveryOffset =
            await ioHelper.framesFromFile(null, frames, testRegistry, null);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          fEqual(
              frames[i], frameWithLength(testFrames[i], frameBytes[i].length));
        }
      });

      test('encrypted', () async {
        var frames = <Frame>[];
        var ioHelper = FrameIoHelperTest(getBytes(frameBytesEncrypted));
        var recoveryOffset = await ioHelper.framesFromFile(
            null, frames, testRegistry, testCrypto);
        expect(recoveryOffset, -1);

        for (var i = 0; i < testFrames.length; i++) {
          fEqual(frames[i],
              frameWithLength(testFrames[i], frameBytesEncrypted[i].length));
        }
      });

      test('returns offset if problem occurs', () async {
        for (var n = 0; n < frameBytes.length; n++) {
          var frame = frameBytes[n];
          var bytesBefore = getBytes(frameBytes.sublist(0, n));
          for (var i = 0; i < frame.length - 1; i++) {
            var bytes = bytesBefore + frame.sublist(0, i);
            var ioHelper = FrameIoHelperTest(Uint8List.fromList(bytes));
            var frames = <Frame>[];
            var recoveryOffset =
                await ioHelper.framesFromFile(null, frames, testRegistry, null);
            expect(recoveryOffset, i == 0 ? -1 : bytesBefore.length);

            var framesBefore = testFrames.sublist(0, n);
            for (var i = 0; i < framesBefore.length; i++) {
              fEqual(frames[i],
                  frameWithLength(framesBefore[i], frameBytes[i].length));
            }
          }
        }
      });
    });
  });
}
