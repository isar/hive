import 'dart:io';

class BufferedFileWriter {
  static const defaultMaxBufferSize = 64000;

  final RandomAccessFile file;

  final int maxBufferSize;

  final _buffer = BytesBuilder(copy: true);

  BufferedFileWriter(this.file, [this.maxBufferSize = defaultMaxBufferSize]);

  Future<void> write(List<int> bytes) {
    _buffer.add(bytes);
    if (_buffer.length >= maxBufferSize) {
      return flush();
    }
    return Future.value();
  }

  Future<void> flush() {
    if (_buffer.isNotEmpty) {
      return file.writeFrom(_buffer.takeBytes());
    } else {
      return Future.value();
    }
  }
}
