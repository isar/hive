import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';

class FrameIoHelper {
  Future<int> readFrameKeysFromFile(
      String path, List<Frame> frames, CryptoHelper crypto) async {
    var bufferedFile = await BufferedFileReader.fromFile(path);
    try {
      while (true) {
        var frameOffset = bufferedFile.offset;
        var lengthBytes = (await bufferedFile.read(4)).toList();
        if (lengthBytes.isEmpty) break;

        var frameLength = bytesToUint32(lengthBytes);
        var frameBytes = await bufferedFile.read(frameLength - 4);
        if (!Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc)) {
          await bufferedFile.close();
          return frameOffset;
        }
        var frameReader = BinaryReaderImpl(frameBytes, null, frameLength - 8);
        var frame =
            Frame.decodeBody(frameReader, true, false, frameLength, null);
        frames.add(frame);
      }
    } finally {
      await bufferedFile.close();
    }

    return null;
  }

  Future<int> readFramesFromFile(String path, List<Frame> frames,
      TypeRegistry registry, CryptoHelper crypto) async {
    var bytes = await File(path).readAsBytes() as Uint8List;
    var reader = BinaryReaderImpl(bytes, registry);

    while (reader.availableBytes != 0) {
      var frameOffset = reader.usedBytes;

      var lengthBytes = reader.readByteList(4);
      var frameLength = bytesToUint32(lengthBytes);
      var frameBytes = reader.viewBytes(frameLength - 4);

      if (!Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc)) {
        return frameOffset;
      }

      var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
      var frame =
          Frame.decodeBody(frameReader, true, true, frameLength, crypto);
      frames.add(frame);
    }

    return null;
  }
}
