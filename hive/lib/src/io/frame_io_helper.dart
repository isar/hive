import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/binary/frame_helper.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/util/crc32.dart';
import 'package:meta/meta.dart';

class FrameIoHelper extends FrameHelper {
  @visibleForTesting
  Future<RandomAccessFile> openFile(String path) {
    return File(path).open();
  }

  @visibleForTesting
  Future<List<int>> readFile(String path) {
    return File(path).readAsBytes();
  }

  Future<int> keysFromFile(
      String path, Keystore keystore, CryptoHelper crypto) async {
    var raf = await openFile(path);
    var fileReader = BufferedFileReader(raf);
    try {
      return await _KeyReader(fileReader).readKeys(keystore, crypto);
    } finally {
      await raf.close();
    }
  }

  Future<int> framesFromFile(String path, Keystore keystore,
      TypeRegistry registry, CryptoHelper crypto) async {
    var bytes = await readFile(path);
    return framesFromBytes(bytes as Uint8List, keystore, registry, crypto);
  }
}

class _KeyReader {
  final BufferedFileReader fileReader;

  BinaryReaderImpl reader;

  _KeyReader(this.fileReader);

  Future<int> readKeys(Keystore keystore, CryptoHelper crypto) async {
    await _read();
    while (true) {
      var frameOffset = fileReader.offset - reader.availableBytes;

      if (reader.availableBytes < 4) {
        var available = await _read();
        if (available == 0) {
          break;
        } else if (available < 4) {
          return frameOffset;
        }
      }

      var frameLength = reader.peekUint32();
      if (frameLength < 8) return frameOffset;
      if (reader.availableBytes < frameLength) {
        var available = await _read(frameLength);
        if (available < frameLength) {
          return frameOffset;
        }
      }
      var frameBytes = reader.viewBytes(frameLength - 4);
      var computedCrc = Crc32.compute(frameBytes, crc: crypto?.keyCrc ?? 0);
      if (computedCrc != reader.readUint32()) {
        return frameOffset;
      }

      reader.unskip(frameLength - 4);
      var offsetBeforeDecode = reader.usedBytes;
      var frame = Frame.decode(reader, true, null)
        ..length = frameLength
        ..offset = frameOffset;
      reader.skip(frameLength - 4 - (reader.usedBytes - offsetBeforeDecode));
      keystore.insert(frame, false);
    }

    return -1;
  }

  Future<int> _read([int bytes = BufferedFileReader.defaultChunkSize]) async {
    fileReader.unskip(reader?.availableBytes ?? 0);

    var loadedBytes = await fileReader.loadBytes(bytes);
    var buffer = fileReader.viewBytes(loadedBytes);
    reader = BinaryReaderImpl(buffer, null);

    return loadedBytes;
  }
}
