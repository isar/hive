import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:meta/meta.dart';

class FrameIoHelper {
  @visibleForTesting
  Future<RandomAccessFile> openFile(String path) {
    return File(path).open();
  }

  @visibleForTesting
  Future<Uint8List> readFile(String path) {
    return File(path).readAsBytes();
  }

  Future<int> keysFromFile(
      String path, List<Frame> frames, CryptoHelper crypto) async {
    var raf = await openFile(path);
    var fileReader = BufferedFileReader(raf);
    try {
      while (true) {
        var frameOffset = fileReader.offset;
        var lengthBytes = (await fileReader.read(4)).toList();
        if (lengthBytes.isEmpty) {
          break;
        } else if (lengthBytes.length < 4) {
          return frameOffset;
        }

        var frameLength = bytesToUint32(lengthBytes);
        var frameBytes = await fileReader.read(frameLength - 4);
        if (frameBytes.length < frameLength - 4 ||
            !Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc)) {
          return frameOffset;
        }
        var frameReader = BinaryReaderImpl(frameBytes, null, frameLength - 8);
        var frame = Frame.decode(frameReader, true, false, frameLength, null);
        frames.add(frame);
      }
    } finally {
      await raf.close();
    }

    return null;
  }

  Future<int> framesFromFile(String path, List<Frame> frames,
      TypeRegistry registry, CryptoHelper crypto) async {
    var bytes = await readFile(path);
    var reader = BinaryReaderImpl(bytes, registry);

    while (reader.availableBytes != 0) {
      var frameOffset = reader.usedBytes;

      if (reader.availableBytes < 4) {
        return frameOffset;
      }

      var lengthBytes = reader.readByteList(4);
      var frameLength = bytesToUint32(lengthBytes);
      if (reader.availableBytes < frameLength - 4) {
        return frameOffset;
      }
      var frameBytes = reader.viewBytes(frameLength - 4);

      if (!Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc)) {
        return frameOffset;
      }

      var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
      var frame = Frame.decode(frameReader, true, true, frameLength, crypto);
      frames.add(frame);
    }

    return null;
  }
}
