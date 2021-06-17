import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mockito/mockito.dart';

import '../mocks.dart';

void main() {
  group('TimeOfDayAdapter', () {
    test('.read()', () {
      final time = TimeOfDay(hour: 8, minute: 0);
      final BinaryReader binaryReader = MockBinaryReader();
      when(binaryReader.read()).thenReturn(time);

      final readTime = TimeAdapter().read(binaryReader);
      verify(binaryReader.read());
      expect(readTime, time);
    });

    test('.write()', () {
      final time = TimeOfDay(hour: 8, minute: 0);
      final BinaryWriter binaryWriter = MockBinaryWriter();

      TimeAdapter().write(binaryWriter, time);
      verify(binaryWriter.write(time));
    });
  });
}
