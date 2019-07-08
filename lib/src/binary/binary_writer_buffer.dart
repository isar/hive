import 'dart:typed_data';

class BinaryWriterBuffer {
  static const _chunkLength = 512;

  /// Current chunk used to write data into. Once it is full it is
  /// pushed into [_outputChunks] and a new one is allocated.
  Uint8List _outputChunk;

  /// Number of bytes written into the [_outputChunk].
  int _bytesInChunk = 0;

  /// ByteData pointing to [_outputChunk]. Used to write primitive values
  /// more efficiently.
  ByteData _outputChunkData;

  final List<dynamic> _committedChunks = [];

  /// Total amount of bytes used in all chunks.
  int _committedBytes = 0;

  int get writtenBytes => _committedBytes + _bytesInChunk;

  ByteData get byteData => _outputChunkData;

  /// Check if [count] bytes would fit into the current chunk. If they will
  /// not then allocate a new [_outputChunk].
  ///
  /// [count] is assumed to be small enough to fit into the newly allocated
  /// chunk.
  int useBytes(int count) {
    if (_outputChunk == null || (_bytesInChunk + count) > _chunkLength) {
      _commitChunk(true, count);
    }
    var offset = _bytesInChunk;
    _bytesInChunk += count;
    return offset;
  }

  void addBytes(Uint8List chunk) {
    _commitChunk(false);
    _committedChunks.add(chunk);
    _committedChunks.add(chunk.length);
    _committedBytes += chunk.length;
  }

  /// Move the current [_outputChunk] into [_outputChunks].
  void _commitChunk(bool allocateNew, [int minChunkSize]) {
    if (_bytesInChunk != 0) {
      _committedChunks.add(_outputChunk);
      _committedChunks.add(_bytesInChunk);
      _committedBytes += _bytesInChunk;
    }

    if (allocateNew) {
      var newChunkSize = _chunkLength;
      if (minChunkSize != null && minChunkSize > newChunkSize) {
        newChunkSize = minChunkSize;
      }
      _outputChunk = Uint8List(newChunkSize);
      _bytesInChunk = 0;
      _outputChunkData = ByteData.view(_outputChunk.buffer);
    } else {
      _outputChunk = _outputChunkData = null;
      _bytesInChunk = 0;
    }
  }

  void writeTo(Uint8List buffer, [int offset = 0]) {
    _commitChunk(false);

    int outPos = offset; // Output position in the buffer.
    int chunkPos = 0;

    for (int i = 0; i < _committedChunks.length; i++) {
      final chunk = _committedChunks[i];
      final int bytesInChunk = _committedChunks[++i];
      while (chunkPos < bytesInChunk) {
        buffer[outPos++] = chunk[chunkPos++];
      }
      chunkPos = 0;
    }
  }
}
