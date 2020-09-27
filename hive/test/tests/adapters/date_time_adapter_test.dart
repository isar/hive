import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('DateTimeAdapter', () {
    test('.read()', () {
      var now = DateTime.now();
      var binaryReader = BinaryReaderMock();
      when(binaryReader.readInt()).thenReturn(now.millisecondsSinceEpoch);

      var date = DateTimeAdapter().read(binaryReader);
      verify(binaryReader.readInt());
      expect(date, now.subtract(Duration(microseconds: now.microsecond)));
    });

    test('.write()', () {
      var now = DateTime.now();
      var binaryWriter = BinaryWriterMock();

      DateTimeAdapter().write(binaryWriter, now);
      verify(binaryWriter.writeInt(now.millisecondsSinceEpoch));
    });
  });

  group('DateTimeWithTimezoneAdapter', () {
    group('.read()', () {
      test('local', () {
        var now = DateTime.now();
        var binaryReader = BinaryReaderMock();
        when(binaryReader.readInt()).thenReturn(now.millisecondsSinceEpoch);
        when(binaryReader.readBool()).thenReturn(false);
        when(binaryReader.availableBytes).thenReturn(1);

        var date = DateTimeWithTimezoneAdapter().read(binaryReader);
        verifyInOrder([binaryReader.readInt(), binaryReader.readBool()]);
        expect(date, now.subtract(Duration(microseconds: now.microsecond)));
      });

      group('UTC', () {
        test('with timezone info', () {
          var now = DateTime.now().toUtc();
          var binaryReader = BinaryReaderMock();
          when(binaryReader.readInt()).thenReturn(now.millisecondsSinceEpoch);
          when(binaryReader.readBool()).thenReturn(true);
          when(binaryReader.availableBytes).thenReturn(1);

          var date = DateTimeWithTimezoneAdapter().read(binaryReader);
          verifyInOrder([binaryReader.readInt(), binaryReader.readBool()]);
          expect(date, now.subtract(Duration(microseconds: now.microsecond)));
          expect(date.isUtc, true);
        });

        test('without timezone info', () {
          var now = DateTime.now().toUtc();
          var binaryReader = BinaryReaderMock();
          when(binaryReader.readInt()).thenReturn(now.millisecondsSinceEpoch);
          when(binaryReader.availableBytes).thenReturn(0);

          var date = DateTimeWithTimezoneAdapter().read(binaryReader);
          verify(binaryReader.readInt());
          verifyNever(binaryReader.readBool());
          expect(date.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
          expect(date.isUtc, false);
        });
      });
    });

    group('.write()', () {
      test('local', () {
        var now = DateTime.now();
        var binaryWriter = BinaryWriterMock();

        DateTimeWithTimezoneAdapter().write(binaryWriter, now);
        verifyInOrder([
          binaryWriter.writeInt(now.millisecondsSinceEpoch),
          binaryWriter.writeBool(false),
        ]);
      });

      test('UTC', () {
        var now = DateTime.now().toUtc();
        var binaryWriter = BinaryWriterMock();

        DateTimeWithTimezoneAdapter().write(binaryWriter, now);
        verifyInOrder([
          binaryWriter.writeInt(now.millisecondsSinceEpoch),
          binaryWriter.writeBool(true),
        ]);
      });
    });
  });
}
