import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';

class FrameIoHelper {
  Future<List<Frame>> readFrameKeysFromFile(
      String path, CryptoHelper crypto) async {
    var bufferedFile = await BufferedFileReader.fromFile(path);
    var frames = <Frame>[];
    try {
      while (true) {
        var lengthBytes = (await bufferedFile.read(4)).toList();
        if (lengthBytes.isEmpty) break;

        var frameLength = bytesToUint32(lengthBytes);
        var frameBytes = await bufferedFile.read(frameLength - 4);
        Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc);
        var frameReader = BinaryReaderImpl(frameBytes, null, frameLength - 8);
        var frame =
            Frame.decodeBody(frameReader, true, false, frameLength, null);
        frames.add(frame);
      }
    } finally {
      await bufferedFile.close();
    }

    return frames;
  }

  Future<List<Frame>> readFramesFromFile(
      String path, TypeRegistry registry, CryptoHelper crypto) async {
    var bytes = await File(path).readAsBytes() as Uint8List;
    var reader = BinaryReaderImpl(bytes, registry);
    var frames = <Frame>[];
    while (true) {
      if (reader.availableBytes == 0) break;

      var lengthBytes = reader.readByteList(4);
      var frameLength = bytesToUint32(lengthBytes);
      var frameBytes = reader.viewBytes(frameLength - 4);
      Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc);
      var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
      var frame =
          Frame.decodeBody(frameReader, true, true, frameLength, crypto);
      frames.add(frame);
    }

    return frames;
  }
}
