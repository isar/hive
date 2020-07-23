import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/src/adapters/time_adapter.dart';
import 'package:mockito/mockito.dart';

import '../mocks.dart';

void main() {
  group('TimeOfDayAdapter', () {
    test('.read()', () {
      final time = TimeOfDay(hour: 8, minute: 0);
      final BinaryReader binaryReader = BinaryReaderMock();
      when(binaryReader.read()).thenReturn(time);

      final readTime = TimeAdapter().read(binaryReader);
      verify(binaryReader.read());
      expect(readTime, time);
    });

    test('.write()', () {
      final time = TimeOfDay(hour: 8, minute: 0);
      final BinaryWriter binaryWriter = BinaryWriterMock();

      TimeAdapter().write(binaryWriter, time);
      verify(binaryWriter.write(time));
    });
  });
}