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

  BinaryReaderImpl _reader;

  _KeyReader(this.fileReader);

  Future<int> readKeys(Keystore keystore, CryptoHelper crypto) async {
    await _read(4);
    while (true) {
      var frameOffset = fileReader.offset - _reader.availableBytes;

      if (_reader.availableBytes < 4) {
        var available = await _read(4);
        if (available == 0) {
          break;
        } else if (available < 4) {
          return frameOffset;
        }
      }

      var frameLength = _reader.peekUint32();
      if (frameLength < 8) {
        throw HiveError('This is an iternal error. Please open an issue on '
            'GitHub and provide steps to reproduce this problem if possible.');
      }

      if (_reader.availableBytes < frameLength) {
        var available = await _read(frameLength);
        if (available < frameLength) {
          return frameOffset;
        }
      }

      var frameBytes = _reader.viewBytes(frameLength - 4);
      var computedCrc = Crc32.compute(frameBytes, crc: crypto?.keyCrc ?? 0);
      if (computedCrc != _reader.readUint32()) {
        return frameOffset;
      }

      _reader.unskip(frameLength - 4);
      var offsetBeforeDecode = _reader.usedBytes;

      _reader.limitAvailableBytes(frameLength - 8);
      var frame = Frame.decode(_reader, true, null)
        ..length = frameLength
        ..offset = frameOffset;
      _reader.resetLimit();

      _reader.skip(frameLength - 4 - (_reader.usedBytes - offsetBeforeDecode));
      keystore.insert(frame, notify: false);
    }

    return -1;
  }

  Future<int> _read(int bytes) async {
    fileReader.unskip(_reader?.availableBytes ?? 0);

    var loadedBytes = await fileReader.loadBytes(bytes);
    var buffer = fileReader.viewBytes(loadedBytes);
    _reader = BinaryReaderImpl(buffer, null);

    return loadedBytes;
  }
}
