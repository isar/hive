import 'dart:typed_data';

class BytesBuilder {
  int _length = 0;
  final List<Uint8List> _chunks = [];

  void add(List<int> bytes) {
    Uint8List typedBytes;
    if (bytes is Uint8List) {
      typedBytes = bytes;
    } else {
      typedBytes = Uint8List.fromList(bytes);
    }
    _chunks.add(typedBytes);
    _length += typedBytes.length;
  }

  void addByte(int byte) {
    _chunks.add(Uint8List(1)..[0] = byte);
    _length++;
  }

  List<int> toBytes() {
    if (_length == 0) return [];
    var buffer = Uint8List(_length);
    var offset = 0;
    for (var chunk in _chunks) {
      buffer.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return buffer;
  }

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  void clear() {
    _length = 0;
    _chunks.clear();
  }
}
