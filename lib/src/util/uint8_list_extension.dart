import 'dart:typed_data';

extension ListIntX on List<int> {
  int readUint32(int offset) {
    return this[offset] |
        this[offset + 1] << 8 |
        this[offset + 2] << 16 |
        this[offset + 3] << 24;
  }

  void writeUint32(int offset, int value) {
    this[offset] = value;
    this[offset + 1] = value >> 8;
    this[offset + 2] = value >> 16;
    this[offset + 3] = value >> 24;
  }
}

extension Uint8ListX on Uint8List {
  Uint8List view(int offset, int bytes) {
    return Uint8List.view(buffer, offsetInBytes + offset, bytes);
  }
}
