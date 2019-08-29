import 'dart:io';

class BufferedFileWriter {
  static const defaultMaxBufferSize = 1000000;

  final RandomAccessFile file;

  final int maxBufferSize;

  final _buffer = BytesBuilder(copy: false);

  BufferedFileWriter(this.file, [this.maxBufferSize = defaultMaxBufferSize]);

  Future<void> write(List<int> bytes) async {
    if (_buffer.length > maxBufferSize) {
      await flush();
    }
    _buffer.add(bytes);
  }

  Future<void> flush() {
    if (_buffer.isNotEmpty) {
      return file.writeFrom(_buffer.takeBytes());
    } else {
      return Future.value();
    }
  }
}
