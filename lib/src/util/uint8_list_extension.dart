import 'dart:typed_data';

abstract class Uint8ListX {
  static int readUint32(Uint8List buffer, int offset) {
    return buffer[offset] |
        buffer[offset + 1] << 8 |
        buffer[offset + 2] << 16 |
        buffer[offset + 3] << 24;
  }

  static void writeUint32(Uint8List buffer, int offset, int value) {
    buffer[offset] = value;
    buffer[offset + 1] = value >> 8;
    buffer[offset + 2] = value >> 16;
    buffer[offset + 3] = value >> 24;
  }

  static Uint8List view(Uint8List buffer, int offset, int bytes) {
    return Uint8List.view(buffer.buffer, buffer.offsetInBytes + offset, bytes);
  }
}
