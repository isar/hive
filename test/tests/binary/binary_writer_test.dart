import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:dartx/dartx.dart';

import '../frames.dart';
import '../mocks.dart';

List<int> bytes(ByteData byteData) => byteData.buffer.asUint8List();

BinaryWriterImpl getWriter() => BinaryWriterImpl(TypeRegistryImpl());

void main() {
  group('BinaryWriter', () {
    test('.writeByte()', () {
      var bw = getWriter();
      bw.writeByte(0);
      expect(bw.toBytes(), [0]);

      bw = getWriter();
      bw.writeByte(17);
      expect(bw.toBytes(), [17]);

      bw = getWriter();
      bw.writeByte(255);
      expect(bw.toBytes(), [255]);

      bw = getWriter();
      bw.writeByte(257);
      expect(bw.toBytes(), [1]);

      expect(() => bw.writeByte(null), throwsA(anything));
    });

    test('.writeWord()', () {
      var bw = getWriter();
      bw.writeWord(0);
      expect(bw.toBytes(), [0, 0]);

      bw = getWriter();
      bw.writeWord(256);
      expect(bw.toBytes(), [0, 1]);

      bw = getWriter();
      bw.writeWord(65535);
      expect(bw.toBytes(), [255, 255]);

      bw = getWriter();
      bw.writeWord(65536);
      expect(bw.toBytes(), [0, 0]);

      expect(() => bw.writeWord(null), throwsA(anything));
    });

    test('.writeInt32()', () {
      var bd = ByteData(4);

      var bw = getWriter();
      bw.writeInt32(0);
      bd.setInt32(0, 0, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt32(1);
      bd.setInt32(0, 1, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt32(-1);
      bd.setInt32(0, -1, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt32(65535);
      bd.setInt32(0, 65535, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt32(65536);
      bd.setInt32(0, 65536, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt32(-65536);
      bd.setInt32(0, -65536, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt32(-65537);
      bd.setInt32(0, -65537, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      expect(() => bw.writeInt32(null), throwsA(anything));
    });

    test('.writeUint32()', () {
      var bd = ByteData(4);

      var bw = getWriter();
      bw.writeUint32(0);
      bd.setUint32(0, 0, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeUint32(1);
      bd.setUint32(0, 1, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeUint32(2147483647);
      bd.setUint32(0, 2147483647, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeUint32(-2147483648);
      bd.setUint32(0, -2147483648, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      expect(() => bw.writeUint32(null), throwsA(anything));
    });

    test('.writeInt()', () {
      var bd = ByteData(8);

      var bw = getWriter();
      bw.writeInt(0);
      bd.setFloat64(0, 0, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt(1);
      bd.setFloat64(0, 1, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt(-1);
      bd.setFloat64(0, -1, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt(2 ^ 53);
      bd.setFloat64(0, (2 ^ 53).toDouble(), Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeInt(-2 ^ 53);
      bd.setFloat64(0, (-2 ^ 53).toDouble(), Endian.little);
      expect(bw.toBytes(), bytes(bd));

      expect(() => bw.writeInt(null), throwsA(anything));
    });

    test('.writeDouble()', () {
      var bd = ByteData(8);

      var bw = getWriter();
      bw.writeDouble(0);
      bd.setFloat64(0, 0, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeDouble(16.399483);
      bd.setFloat64(0, 16.399483, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeDouble(double.nan);
      bd.setFloat64(0, double.nan, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeDouble(double.infinity);
      bd.setFloat64(0, double.infinity, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeDouble(double.negativeInfinity);
      bd.setFloat64(0, double.negativeInfinity, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeDouble(double.maxFinite);
      bd.setFloat64(0, double.maxFinite, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      bw = getWriter();
      bw.writeDouble(double.minPositive);
      bd.setFloat64(0, double.minPositive, Endian.little);
      expect(bw.toBytes(), bytes(bd));

      expect(() => bw.writeDouble(null), throwsA(anything));
    });

    test('.writeBool()', () {
      var bw = getWriter();
      bw.writeBool(true);
      expect(bw.toBytes(), [1]);

      bw = getWriter();
      bw.writeBool(false);
      expect(bw.toBytes(), [0]);

      expect(() => bw.writeBool(null), throwsA(anything));
    });

    test('.writeAsciiString()', () {
      var bw = getWriter();
      bw.writeAsciiString('');
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeAsciiString('', writeLength: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeAsciiString('T.,r \n');
      expect(bw.toBytes(), [6, 0, 0, 0, 84, 46, 44, 114, 32, 10]);

      bw = getWriter();
      bw.writeAsciiString('T.,r \n', writeLength: false);
      expect(bw.toBytes(), [84, 46, 44, 114, 32, 10]);

      expect(() => bw.writeAsciiString('😍'), throwsA(anything));
      expect(() => bw.writeAsciiString(null), throwsA(anything));
    });

    test('.writeString()', () {
      var bw = getWriter();
      bw.writeString('');
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeString('', writeByteCount: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeString('𠁠🇬🇵');
      expect(bw.toBytes(), [
        12, 0, 0, 0, 0xf0, 0xa0, 0x81, 0xa0, 0xf0, //
        0x9f, 0x87, 0xac, 0xf0, 0x9f, 0x87, 0xb5 //
      ]);

      bw = getWriter();
      bw.writeString('👨‍👨‍👧‍👦', writeByteCount: false);
      expect(bw.toBytes(), [
        0xf0, 0x9f, 0x91, 0xa8, 0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa8, //
        0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa7, 0xe2, 0x80, 0x8d, 0xf0, //
        0x9f, 0x91, 0xa6 //
      ]);

      expect(() => bw.writeString(null), throwsA(anything));
    });

    test('.writeByteList()', () {
      var bw = getWriter();
      bw.writeByteList([]);
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeByteList([], writeLength: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeByteList([1, 2, 3, 4]);
      expect(bw.toBytes(), [4, 0, 0, 0, 1, 2, 3, 4]);

      bw = getWriter();
      bw.writeByteList([1, 2, 3, 4], writeLength: false);
      expect(bw.toBytes(), [1, 2, 3, 4]);

      expect(() => bw.writeByteList(null), throwsA(anything));
    });

    test('.writeIntList()', () {
      var bw = getWriter();
      bw.writeIntList([]);
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeIntList([], writeLength: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeIntList([1, 2]);
      expect(bw.toBytes(),
          [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 64]);

      bw = getWriter();
      bw.writeIntList([1, 2], writeLength: false);
      expect(
          bw.toBytes(), [0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 64]);

      expect(() => bw.writeIntList(null), throwsA(anything));
    });

    test('.writeDoubleList()', () {
      var bw = getWriter();
      bw.writeDoubleList([]);
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeDoubleList([], writeLength: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeDoubleList([1.0]);
      expect(bw.toBytes(), [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 240, 63]);

      bw = getWriter();
      bw.writeDoubleList([1.0], writeLength: false);
      expect(bw.toBytes(), [0, 0, 0, 0, 0, 0, 240, 63]);

      expect(() => bw.writeDoubleList(null), throwsA(anything));
    });

    test('.writeBoolList()', () {
      var bw = getWriter();
      bw.writeBoolList([]);
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeBoolList([], writeLength: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeBoolList([true, false, true]);
      expect(bw.toBytes(), [3, 0, 0, 0, 1, 0, 1]);

      bw = getWriter();
      bw.writeBoolList([true, false, true], writeLength: false);
      expect(bw.toBytes(), [1, 0, 1]);

      expect(() => bw.writeBoolList(null), throwsA(anything));
    });

    test('.writeStringList()', () {
      var bw = getWriter();
      bw.writeStringList([]);
      expect(bw.toBytes(), [0, 0, 0, 0]);

      bw = getWriter();
      bw.writeStringList([], writeLength: false);
      expect(bw.toBytes(), []);

      bw = getWriter();
      bw.writeStringList(['a', '🧙‍♂️']);
      expect(bw.toBytes(), [
        2, 0, 0, 0, 1, 0, 0, 0, 97, 13, 0, 0, 0, 0xf0, 0x9f, 0xa7, //
        0x99, 0xe2, 0x80, 0x8d, 0xe2, 0x99, 0x82, 0xef, 0xb8, 0x8f //
      ]);

      bw = getWriter();
      bw.writeStringList(['a', 'ab'], writeLength: false);
      expect(bw.toBytes(), [1, 0, 0, 0, 97, 2, 0, 0, 0, 97, 98]);

      expect(() => bw.writeBoolList(null), throwsA(anything));
    });

    test('.writeList()', () {
      var bw = getWriter();
      bw.writeList(<dynamic>['h', true]);
      expect(bw.toBytes(), [
        2, 0, 0, 0, //
        FrameValueType.stringT.index, 1, 0, 0, 0, 0x68, //
        FrameValueType.boolT.index, 1 //
      ]);

      bw = getWriter();
      bw.writeList(<dynamic>['h', true], writeLength: false);
      expect(bw.toBytes(), [
        FrameValueType.stringT.index, 1, 0, 0, 0, 0x68, //
        FrameValueType.boolT.index, 1 //
      ]);
    });

    test('.writeMap()', () {
      var bw = getWriter();
      bw.writeMap({true: 'h', 'hi': true});
      expect(bw.toBytes(), [
        2, 0, 0, 0, //
        FrameValueType.boolT.index, 1, //
        FrameValueType.stringT.index, 1, 0, 0, 0, 0x68, //
        FrameValueType.stringT.index, 2, 0, 0, 0, 0x68, 0x69, //
        FrameValueType.boolT.index, 1 //
      ]);

      bw = getWriter();
      bw.writeMap({true: 'h', 'hi': true}, writeLength: false);
      expect(bw.toBytes(), [
        FrameValueType.boolT.index, 1, //
        FrameValueType.stringT.index, 1, 0, 0, 0, 0x68, //
        FrameValueType.stringT.index, 2, 0, 0, 0, 0x68, 0x69, //
        FrameValueType.boolT.index, 1 //
      ]);
    });

    group('.writeHiveList()', () {
      var box = BoxMock();
      when(box.name).thenReturn('Box');

      var obj = HiveObjectMock();
      when(obj.box).thenReturn(box);
      when(obj.key).thenReturn('key');

      test('write length', () {
        var list = HiveListImpl(box, objects: [obj]);
        var bw = getWriter();
        bw.writeHiveList(list);

        expect(bw.toBytes(), [
          1, 0, 0, 0, 3, 66, 111, 120, //
          1, 3, 107, 101, 121, //
        ]);
      });

      test('omit length', () {
        var list = HiveListImpl(box, objects: [obj]);
        var bw = getWriter();
        bw.writeHiveList(list, writeLength: false);

        expect(bw.toBytes(), [
          3, 66, 111, 120, //
          1, 3, 107, 101, 121, //
        ]);
      });
    });

    group('.writeFrame()', () {
      test('normal', () {
        testFrames.forEachIndexed((frame, i) {
          var writer = BinaryWriterImpl(testRegistry);
          expect(writer.writeFrame(frame), frameBytes[i].length);
          expect(writer.toBytes(), frameBytes[i]);
        });
      });

      test('encrypted', () {
        testFrames.forEachIndexed((frame, i) {
          var writer = BinaryWriterImpl(testRegistry);
          expect(writer.writeFrame(frame, crypto: testCrypto),
              frameBytesEncrypted[i].length);
          expect(writer.toBytes(), frameBytesEncrypted[i]);
        });
      });
    });

    group('.write()', () {
      test('null', () {
        var bw = getWriter();
        bw.write(null, writeTypeId: false);
        expect(bw.toBytes(), []);

        bw = getWriter();
        bw.write(null, writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.nullT.index]);
      });

      test('int', () {
        var bd = ByteData(8)..setFloat64(0, 12345, Endian.little);

        var bw = getWriter();
        bw.write(12345, writeTypeId: false);
        expect(bw.toBytes(), bytes(bd));

        bw = getWriter();
        bw.write(12345, writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.intT.index, ...bytes(bd)]);
      });

      test('double', () {
        var bd = ByteData(8)..setFloat64(0, 123.456, Endian.little);

        var bw = getWriter();
        bw.write(123.456, writeTypeId: false);
        expect(bw.toBytes(), bytes(bd));

        bw = getWriter();
        bw.write(123.456, writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.doubleT.index, ...bytes(bd)]);
      });

      test('bool', () {
        var bw = getWriter();
        bw.write(true, writeTypeId: false);
        expect(bw.toBytes(), [1]);

        bw = getWriter();
        bw.write(true, writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.boolT.index, 1]);
      });

      test('string', () {
        var bw = getWriter();
        bw.write('hi', writeTypeId: false);
        expect(bw.toBytes(), [2, 0, 0, 0, 0x68, 0x69]);

        bw = getWriter();
        bw.write('hi', writeTypeId: true);
        expect(bw.toBytes(),
            [FrameValueType.stringT.index, 2, 0, 0, 0, 0x68, 0x69]);
      });

      test('HiveList', () {
        var box = BoxMock();
        when(box.name).thenReturn('Box');

        var obj = HiveObjectMock();
        when(obj.box).thenReturn(box);
        when(obj.key).thenReturn('key');

        var list = HiveListImpl(box, objects: [obj]);
        var bw = getWriter();
        bw.write(list);

        expect(bw.toBytes(), [
          FrameValueType.hiveListT.index,
          1, 0, 0, 0, 3, 66, 111, 120, //
          1, 3, 107, 101, 121, //
        ]);
      });

      test('byte list', () {
        var bw = getWriter();
        bw.write(Uint8List.fromList([1, 2, 3, 4]), writeTypeId: false);
        expect(bw.toBytes(), [4, 0, 0, 0, 1, 2, 3, 4]);

        bw = getWriter();
        bw.write(Uint8List.fromList([1, 2, 3, 4]), writeTypeId: true);
        expect(bw.toBytes(),
            [FrameValueType.byteListT.index, 4, 0, 0, 0, 1, 2, 3, 4]);
      });

      test('int list', () {
        var bd = ByteData(20)
          ..setUint32(0, 2, Endian.little)
          ..setFloat64(4, 123, Endian.little)
          ..setFloat64(12, 45, Endian.little);

        var bw = getWriter();
        bw.write([123, 45], writeTypeId: false);
        expect(bw.toBytes(), bytes(bd));

        bw = getWriter();
        bw.write([123, 45], writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.intListT.index, ...bytes(bd)]);
      });

      test('double list', () {
        var bd = ByteData(20)
          ..setUint32(0, 2, Endian.little)
          ..setFloat64(4, 123.456, Endian.little)
          ..setFloat64(12, 456.321, Endian.little);

        var bw = getWriter();
        bw.write([123.456, 456.321], writeTypeId: false);
        expect(bw.toBytes(), bytes(bd));

        bw = getWriter();
        bw.write([123.456, 456.321], writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.doubleListT.index, ...bytes(bd)]);
      });

      test('bool list', () {
        var bd = ByteData(6)
          ..setUint32(0, 2, Endian.little)
          ..setUint8(4, 0)
          ..setUint8(5, 1);

        var bw = getWriter();
        bw.write([false, true], writeTypeId: false);
        expect(bw.toBytes(), bytes(bd));

        bw = getWriter();
        bw.write([false, true], writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.boolListT.index, ...bytes(bd)]);
      });

      test('string list', () {
        var bw = getWriter();
        bw.write(['h', 'hi'], writeTypeId: false);
        expect(bw.toBytes(), [
          2, 0, 0, 0, //
          1, 0, 0, 0, 0x68, //
          2, 0, 0, 0, 0x68, 0x69, //
        ]);

        bw = getWriter();
        bw.write(['h', 'hi'], writeTypeId: true);
        expect(bw.toBytes(), [
          FrameValueType.stringListT.index, 2, 0, 0, 0, //
          1, 0, 0, 0, 0x68, //
          2, 0, 0, 0, 0x68, 0x69, //
        ]);
      });

      test('list with null', () {
        var bd = ByteData(23)
          ..setUint32(0, 3, Endian.little)
          ..setUint8(4, FrameValueType.intT.index)
          ..setFloat64(5, 123, Endian.little)
          ..setUint8(13, FrameValueType.intT.index)
          ..setFloat64(14, 45, Endian.little)
          ..setUint8(22, FrameValueType.nullT.index);

        var bw = getWriter();
        bw.write([123, 45, null], writeTypeId: false);
        expect(bw.toBytes(), bytes(bd));

        bw = getWriter();
        bw.write([123, 45, null], writeTypeId: true);
        expect(bw.toBytes(), [FrameValueType.listT.index, ...bytes(bd)]);
      });
    });
  });
}
