import 'dart:io';

import 'dart:typed_data';

import 'package:hive/src/binary/frame.dart';

class BufferedFileReader {
  static const defaultChunkSize = Frame.maxFrameLength;

  final RandomAccessFile file;
  final int chunkSize;
  Uint8List _buffer;
  int _bufferSize = 0;
  int _bufferOffset = 0;
  int _fileOffset = 0;

  int get _remainingInBuffer => _bufferSize - _bufferOffset;

  int get offset => _fileOffset - _remainingInBuffer;

  BufferedFileReader._(this.file, this.chunkSize);

  static Future<BufferedFileReader> fromFile(String path,
      [int chunkSize = defaultChunkSize]) async {
    var raf = await File(path).open();
    return BufferedFileReader._(raf, chunkSize);
  }

  Future<int> skip(int bytes) async {
    if (_remainingInBuffer >= bytes) {
      _bufferOffset += bytes;
      return bytes;
    } else {
      var canSkip = _remainingInBuffer;
      _bufferOffset += canSkip;
      var additionallySkipped = (await read(bytes - canSkip)).length;
      return canSkip + additionallySkipped;
    }
  }

  Future<Uint8List> read(int bytes) async {
    if (_buffer == null) {
      _buffer = Uint8List(chunkSize);
      await _readChunk(null, 0, 0);
    }
    if (_remainingInBuffer >= bytes) {
      var view = Uint8List.view(_buffer.buffer, _bufferOffset, bytes);
      _bufferOffset += bytes;
      return view;
    } else if (_bufferSize < chunkSize) {
      var view =
          Uint8List.view(_buffer.buffer, _bufferOffset, _remainingInBuffer);
      _bufferOffset = _bufferSize;
      return view;
    } else {
      if (_buffer.length < bytes) {
        _buffer = Uint8List(bytes);
      }
      await _readChunk(_buffer, _bufferOffset, _remainingInBuffer);
      return read(bytes);
    }
  }

  Future _readChunk(Uint8List oldChunk, int offset, int remaining) async {
    if (oldChunk != null) {
      for (int i = 0; i < remaining; i++) {
        _buffer[i] = _buffer[offset + i];
      }
    }

    _bufferOffset = 0;
    var readBytes = await file.readInto(_buffer, remaining);
    _bufferSize = remaining + readBytes;
    _fileOffset += readBytes;
  }

  Future close() {
    _buffer = null;
    return file.close();
  }
}
