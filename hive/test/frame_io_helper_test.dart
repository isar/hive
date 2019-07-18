@TestOn('vm')

import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/io/frame_io_helper.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'frame_test.dart';
import 'generated/frames.g.dart';
import 'generated/frames_encrypted.g.dart';

Future<File> getByteFile(List<Uint8List> list) {
  var builder = BytesBuilder();
  for (var b in list) {
    builder.add(b);
  }
  var bytes = Uint8List.fromList(builder.toBytes());
  return getTempFile(bytes);
}

void main() {
  group('readFrameKeysFromFile()', () {
    test('frame', () async {
      var file = await getByteFile(frameBytes);
      var frames = await readFrameKeysFromFile(file.path, null);

      for (var i = 0; i < testFrames.length; i++) {
        expect(frames[i].key, testFrames[i].key);
        expect(frames[i].length, frameBytes[i].length);
      }
    });

    test('encrypted', () async {
      var file = await getByteFile(frameBytesEncrypted);
      var frames = await readFrameKeysFromFile(file.path, getDebugCrypto());

      for (var i = 0; i < testFrames.length; i++) {
        expect(frames[i].key, testFrames[i].key);
        expect(frames[i].length, frameBytesEncrypted[i].length);
      }
    });
  });

  group('readFramesFromFile()', () {
    test('frame', () async {
      var file = await getByteFile(frameBytes);
      var frames = await readFramesFromFile(file.path, null, null);

      for (var i = 0; i < testFrames.length; i++) {
        expect(frames[i].key, testFrames[i].key);
        expect(frames[i].value, testFrames[i].value);
        expect(frames[i].length, frameBytes[i].length);
      }
    });

    test('encrypted', () async {
      var file = await getByteFile(frameBytesEncrypted);
      var frames = await readFramesFromFile(file.path, null, getDebugCrypto());
      for (var i = 0; i < testFrames.length; i++) {
        expect(frames[i].key, testFrames[i].key);
        expect(frames[i].value, testFrames[i].value);
        expect(frames[i].length, frameBytesEncrypted[i].length);
      }
    });
  });
}
