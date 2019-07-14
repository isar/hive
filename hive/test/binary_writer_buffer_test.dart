import 'dart:typed_data';

import 'package:hive/src/binary/binary_writer_buffer.dart';
import 'package:test/test.dart';

void main() {
  test('use bytes', () {
    var b = BinaryWriterBuffer();
    expect(b.writtenBytes, 0);

    var offset = b.useBytes(100);
    expect(offset, 0);
    expect(b.writtenBytes, 100);
    b.byteData.setUint8(99, 1);

    offset = b.useBytes(100);
    expect(offset, 100);
    expect(b.writtenBytes, 200);
    b.byteData.setUint8(199, 2);

    offset = b.useBytes(100000);
    expect(offset, 0);
    expect(b.writtenBytes, 100200);
    b.byteData.setUint8(99999, 3);

    var buffer = Uint8List(b.writtenBytes);
    b.writeTo(buffer);
    expect(buffer[99], 1);
    expect(buffer[199], 2);
    expect(buffer[100199], 3);
  });

  test('add bytes', () {
    var b = BinaryWriterBuffer();

    var offset = b.useBytes(1);
    b.byteData.setUint8(0, 20);
    expect(offset, 0);
    expect(b.writtenBytes, 1);

    b.addBytes(Uint8List.fromList([5, 6, 7]));
    expect(b.writtenBytes, 4);

    offset = b.useBytes(1);
    b.byteData.setUint8(0, 17);
    expect(offset, 0);
    expect(b.writtenBytes, 5);

    var buffer = Uint8List(b.writtenBytes);
    b.writeTo(buffer);
    expect(buffer, [20, 5, 6, 7, 17]);
  });

  test('writeTo', () {});
}
