import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

BinaryReader fromByteData(ByteData byteData) {
  return BinaryReaderImpl(byteData.buffer.asUint8List(), TypeRegistryImpl());
}

BinaryReader fromBytes(List<int> bytes) {
  return BinaryReaderImpl(Uint8List.fromList(bytes), TypeRegistryImpl());
}

void main() {
  test('skip', () {
    var byteData = ByteData(20);
    var br = fromByteData(byteData);

    expect(br.availableBytes, 20);
    expect(br.usedBytes, 0);

    br.skip(5);
    expect(br.availableBytes, 15);
    expect(br.usedBytes, 5);

    br.skip(0);
    expect(br.availableBytes, 15);
    expect(br.usedBytes, 5);

    br.skip(15);
    expect(br.availableBytes, 0);
    expect(br.usedBytes, 20);

    expect(() => br.skip(1), throwsA(anything));
  });

  test('read byte', () {
    var byteData = ByteData(3)
      ..setUint8(0, 0)
      ..setUint8(1, 17)
      ..setUint8(2, 255);
    var br = fromByteData(byteData);

    expect(br.readByte(), 0);
    expect(br.readByte(), 17);
    expect(br.readByte(), 255);
    expect(() => br.readByte(), throwsA(anything));
  });

  test('view bytes', () {
    var byteData = ByteData(3)
      ..setUint8(0, 0)
      ..setUint8(1, 17)
      ..setUint8(2, 255);
    var br = fromByteData(byteData);

    var bytes = br.viewBytes(3);
    expect(bytes, [0, 17, 255]);

    byteData.setUint8(1, 57);
    expect(bytes, [0, 57, 255]);

    expect(() => br.viewBytes(1), throwsA(anything));
  });

  test('read bytes', () {
    var byteData = ByteData(3)
      ..setUint8(0, 0)
      ..setUint8(1, 17)
      ..setUint8(2, 255);
    var br = fromByteData(byteData);

    expect(br.readBytes(3), [0, 17, 255]);
    expect(() => br.readBytes(1), throwsA(anything));
  });

  test('read word', () {
    var byteData = ByteData(4)
      ..setUint16(0, 0, Endian.little)
      ..setUint16(2, 65535, Endian.little);
    var br = fromByteData(byteData);

    expect(br.readWord(), 0);
    expect(br.readWord(), 65535);
    expect(() => br.readWord(), throwsA(anything));
  });

  test('read int32', () {
    var byteData = ByteData(12)
      ..setInt32(0, 0, Endian.little)
      ..setInt32(4, 65535, Endian.little)
      ..setInt32(8, -65536, Endian.little);
    var br = fromByteData(byteData);

    expect(br.readInt32(), 0);
    expect(br.readInt32(), 65535);
    expect(br.readInt32(), -65536);
    expect(() => br.readInt32(), throwsA(anything));
  });

  test('read unsigned int32', () {
    var byteData = ByteData(8)
      ..setUint32(0, 0, Endian.little)
      ..setUint32(4, 4294967295, Endian.little);
    var br = fromByteData(byteData);

    expect(br.readUint32(), 0);
    expect(br.readUint32(), 4294967295);
    expect(() => br.readUint32(), throwsA(anything));
  });

  test('read int', () {
    var byteData = ByteData(24)
      ..setFloat64(0, 0, Endian.little)
      ..setFloat64(8, (2 ^ 53).toDouble(), Endian.little)
      ..setFloat64(16, (-2 ^ 53).toDouble(), Endian.little);
    var br = fromByteData(byteData);

    expect(br.readInt(), 0);
    expect(br.readInt(), 2 ^ 53);
    expect(br.readInt(), -2 ^ 53);
    expect(() => br.readInt(), throwsA(anything));
  });

  test('read double', () {
    var byteData = ByteData(48)
      ..setFloat64(0, 0, Endian.little)
      ..setFloat64(8, double.nan, Endian.little)
      ..setFloat64(16, double.infinity, Endian.little)
      ..setFloat64(24, double.negativeInfinity, Endian.little)
      ..setFloat64(32, double.maxFinite, Endian.little)
      ..setFloat64(40, double.minPositive, Endian.little);
    var br = fromByteData(byteData);

    expect(br.readDouble(), 0);
    expect(br.readDouble().isNaN, true);
    expect(br.readDouble(), double.infinity);
    expect(br.readDouble(), double.negativeInfinity);
    expect(br.readDouble(), double.maxFinite);
    expect(br.readDouble(), double.minPositive);
    expect(() => br.readDouble(), throwsA(anything));
  });

  test('read bool', () {
    var byteData = ByteData(3)..setUint8(0, 1)..setUint8(1, 0)..setUint8(2, 2);
    var br = fromByteData(byteData);

    expect(br.readBool(), true);
    expect(br.readBool(), false);
    expect(br.readBool(), true);
    expect(() => br.readBool(), throwsA(anything));
  });

  test('read ascii string', () {
    var br = fromBytes([0, 0]);
    expect(br.readAsciiString(), '');

    br = fromBytes([]);
    expect(br.readAsciiString(0), '');

    br = fromBytes([6, 0, 84, 46, 44, 114, 32, 10]);
    expect(br.readAsciiString(), 'T.,r \n');

    br = fromBytes([84, 46, 44, 114, 32, 10]);
    expect(br.readAsciiString(6), 'T.,r \n');

    expect(() => br.readAsciiString(), throwsRangeError);
  });

  test('read string', () {
    var br = fromBytes([0, 0]);
    expect(br.readString(), '');

    br = fromBytes([]);
    expect(br.readString(0), '');

    br = fromBytes([
      12, 0, 0xf0, 0xa0, 0x81, 0xa0, 0xf0, //
      0x9f, 0x87, 0xac, 0xf0, 0x9f, 0x87, 0xb5 //
    ]);
    expect(br.readString(), '𠁠🇬🇵');

    br = fromBytes([
      0xf0, 0x9f, 0x91, 0xa8, 0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa8, //
      0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa7, 0xe2, 0x80, 0x8d, 0xf0, //
      0x9f, 0x91, 0xa6 //
    ]);
    expect(br.readString(25), '👨‍👨‍👧‍👦');

    expect(() => br.readString(), throwsRangeError);
  });

  test('read int list', () {
    var br = fromBytes([0, 0]);
    expect(br.readIntList(), []);

    br = fromBytes([]);
    expect(br.readIntList(0), []);

    br = fromBytes([2, 0, 0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 64]);
    expect(br.readIntList(), [1, 2]);

    br = fromBytes([0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 64]);
    expect(br.readIntList(2), [1, 2]);

    expect(() => br.readIntList(), throwsRangeError);
  });

  test('read double list', () {
    var br = fromBytes([0, 0]);
    expect(br.readDoubleList(), []);

    br = fromBytes([]);
    expect(br.readDoubleList(0), []);

    br = fromBytes([1, 0, 0, 0, 0, 0, 0, 0, 240, 63]);
    expect(br.readDoubleList(), [1.0]);

    br = fromBytes([0, 0, 0, 0, 0, 0, 240, 63]);
    expect(br.readDoubleList(1), [1.0]);

    expect(() => br.readDoubleList(), throwsRangeError);
  });

  test('read bool list', () {
    var br = fromBytes([0, 0]);
    expect(br.readBoolList(), []);

    br = fromBytes([]);
    expect(br.readBoolList(0), []);

    br = fromBytes([3, 0, 1, 0, 25]);
    expect(br.readBoolList(), [true, false, true]);

    br = fromBytes([1, 0, 136]);
    expect(br.readBoolList(3), [true, false, true]);

    expect(() => br.readBoolList(), throwsRangeError);
  });

  test('read string list', () {
    var br = fromBytes([0, 0]);
    expect(br.readStringList(), []);

    br = fromBytes([]);
    expect(br.readStringList(0), []);

    br = fromBytes([
      2, 0, 1, 0, 97, 13, 0, 0xf0, 0x9f, 0xa7, 0x99, 0xe2, 0x80, 0x8d, 0xe2, //
      0x99, 0x82, 0xef, 0xb8, 0x8f //
    ]);
    expect(br.readStringList(), ['a', '🧙‍♂️']);

    br = fromBytes([1, 0, 97, 2, 0, 97, 98]);
    expect(br.readStringList(2), ['a', 'ab']);

    expect(() => br.readStringList(), throwsRangeError);
  });

  test('read list', () {
    var br = fromBytes([
      2, 0, FrameValueType.bool_.index, 1, //
      FrameValueType.string_.index, 2, 0, 0x68, 0x69 //
    ]);
    expect(br.readList(), [true, 'hi']);

    br = fromBytes([
      FrameValueType.bool_.index, 1, //
      FrameValueType.string_.index, 2, 0, 0x68, 0x69 //
    ]);
    expect(br.readList(2), [true, 'hi']);

    expect(() => br.readList(), throwsRangeError);
  });

  test('read map', () {
    var br = fromBytes([
      2, 0, FrameValueType.string_.index, 2, 0, 0x68, 0x69, //
      FrameValueType.bool_.index, 1, FrameValueType.bool_.index, //
      0, FrameValueType.string_.index, 2, 0, 0x68, 0x69 //
    ]);
    expect(br.readMap(), {'hi': true, false: 'hi'});

    br = fromBytes([
      FrameValueType.string_.index, 2, 0, 0x68, 0x69, //
      FrameValueType.bool_.index, 1, FrameValueType.bool_.index, //
      0, FrameValueType.string_.index, 2, 0, 0x68, 0x69 //
    ]);
    expect(br.readMap(2), {'hi': true, false: 'hi'});

    expect(() => br.readMap(), throwsA(anything));
  });

  group('read value', () {
    test('null', () {
      var br = fromBytes([]);
      expect(br.read(FrameValueType.null_.index), null);

      br = fromBytes([FrameValueType.null_.index]);
      expect(br.read(), null);
    });

    test('int', () {
      var byteData = ByteData(8)..setFloat64(0, 12345, Endian.little);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.int_.index), 12345);

      byteData = ByteData(9)
        ..setUint8(0, FrameValueType.int_.index)
        ..setFloat64(1, 12345, Endian.little);
      br = fromByteData(byteData);
      expect(br.read(), 12345);
    });

    test('double', () {
      var byteData = ByteData(8)..setFloat64(0, 234.99283, Endian.little);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.double_.index), 234.99283);

      byteData = ByteData(9)
        ..setUint8(0, FrameValueType.double_.index)
        ..setFloat64(1, 234.99283, Endian.little);
      br = fromByteData(byteData);
      expect(br.read(), 234.99283);
    });

    test('bool', () {
      var byteData = ByteData(2)..setUint8(0, 1);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.bool_.index), true);

      byteData = ByteData(2)
        ..setUint8(0, FrameValueType.bool_.index)
        ..setInt8(1, 1);
      br = fromByteData(byteData);
      expect(br.read(), true);
    });

    test('string', () {
      var br = fromBytes([2, 0, 0x68, 0x69]);
      expect(br.read(FrameValueType.string_.index), 'hi');

      br = fromBytes([FrameValueType.string_.index, 2, 0, 0x68, 0x69]);
      expect(br.read(), 'hi');
    });

    test('int list', () {
      var byteData = ByteData(18)
        ..setUint16(0, 2, Endian.little)
        ..setFloat64(2, 12345, Endian.little)
        ..setFloat64(10, 123, Endian.little);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.int_list_.index), [12345, 123]);

      byteData = ByteData(19)
        ..setUint8(0, FrameValueType.int_list_.index)
        ..setUint16(1, 2, Endian.little)
        ..setFloat64(3, 12345, Endian.little)
        ..setFloat64(11, 123, Endian.little);
      br = fromByteData(byteData);
      expect(br.read(), [12345, 123]);
    });

    test('double list', () {
      var byteData = ByteData(18)
        ..setUint16(0, 2, Endian.little)
        ..setFloat64(2, 11.11, Endian.little)
        ..setFloat64(10, 12.12, Endian.little);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.double_list_.index), [11.11, 12.12]);

      byteData = ByteData(19)
        ..setUint8(0, FrameValueType.double_list_.index)
        ..setUint16(1, 2, Endian.little)
        ..setFloat64(3, 11.11, Endian.little)
        ..setFloat64(11, 12.12, Endian.little);
      br = fromByteData(byteData);
      expect(br.read(), [11.11, 12.12]);
    });

    test('bool list', () {
      var byteData = ByteData(4)
        ..setUint16(0, 2, Endian.little)
        ..setUint8(2, 0)
        ..setUint8(3, 1);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.bool_list_.index), [false, true]);

      byteData = ByteData(5)
        ..setUint8(0, FrameValueType.bool_list_.index)
        ..setUint16(1, 2, Endian.little)
        ..setUint8(3, 0)
        ..setUint8(4, 1);
      br = fromByteData(byteData);
      expect(br.read(), [false, true]);
    });

    test('string list', () {
      var br = fromBytes([2, 0, 2, 0, 0x68, 0x69, 1, 0, 0x68]);
      expect(br.read(FrameValueType.string_list_.index), ['hi', 'h']);

      br = fromBytes([
        FrameValueType.string_list_.index,
        2, 0, 2, 0, 0x68, 0x69, 1, 0, 0x68 //
      ]);
      expect(br.read(), ['hi', 'h']);
    });

    test('list with null', () {
      var byteData = ByteData(21)
        ..setUint16(0, 3, Endian.little)
        ..setUint8(2, FrameValueType.int_.index)
        ..setFloat64(3, 12345, Endian.little)
        ..setUint8(11, FrameValueType.int_.index)
        ..setFloat64(12, 123, Endian.little)
        ..setUint8(20, FrameValueType.null_.index);
      var br = fromByteData(byteData);
      expect(br.read(FrameValueType.list_.index), [12345, 123, null]);

      byteData = ByteData(22)
        ..setInt8(0, FrameValueType.list_.index)
        ..setUint16(1, 3, Endian.little)
        ..setUint8(3, FrameValueType.int_.index)
        ..setFloat64(4, 12345, Endian.little)
        ..setUint8(12, FrameValueType.int_.index)
        ..setFloat64(13, 123, Endian.little)
        ..setUint8(21, FrameValueType.null_.index);
      br = fromByteData(byteData);
      expect(br.read(), [12345, 123, null]);
    });
  });
}
