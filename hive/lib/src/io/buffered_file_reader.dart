import 'dart:io';

import 'dart:typed_data';

import 'package:meta/meta.dart';

class BufferedFileReader {
  static const defaultChunkSize = 1000 * 64;

  final RandomAccessFile file;

  @visibleForTesting
  Uint8List buffer;
  int _bufferSize = 0;
  int _bufferOffset = 0;
  int _fileOffset = 0;

  int get remainingInBuffer => _bufferSize - _bufferOffset;

  int get offset => _fileOffset - remainingInBuffer;

  BufferedFileReader(this.file, [int bufferSize = defaultChunkSize])
      : buffer = Uint8List(bufferSize);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int bytes) {
    assert(bytes >= 0 && remainingInBuffer >= bytes);
    _bufferOffset += bytes;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List viewBytes(int bytes) {
    assert(bytes >= 0 && remainingInBuffer >= bytes);
    var view = Uint8List.view(buffer.buffer, _bufferOffset, bytes);
    _bufferOffset += bytes;
    return view;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List peekBytes(int bytes) {
    assert(bytes >= 0 && remainingInBuffer >= bytes);
    return Uint8List.view(buffer.buffer, _bufferOffset, bytes);
  }

  Future<int> loadBytes(int bytes) async {
    assert(bytes > 0);
    var remaining = remainingInBuffer;
    if (remaining >= bytes) {
      return remaining;
    } else {
      var oldBuffer = buffer;
      if (buffer.length < bytes) {
        buffer = Uint8List(bytes);
      }

      for (var i = 0; i < remaining; i++) {
        buffer[i] = oldBuffer[_bufferOffset + i];
      }

      _bufferOffset = 0;
      var readBytes = await file.readInto(buffer, remaining);
      _bufferSize = remaining + readBytes;
      _fileOffset += readBytes;

      return _bufferSize;
    }
  }
}
