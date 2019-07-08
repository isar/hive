import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  test("read", () {
    var now = DateTime.now();
    var binaryReader = BinaryReaderMock();
    when(binaryReader.readInt()).thenReturn(now.microsecondsSinceEpoch);

    var date = DateTimeAdapter().read(binaryReader);
    verify(binaryReader.readInt());
    expect(date, now);
  });

  test("write", () {
    var now = DateTime.now();
    var binaryWriter = BinaryWriterMock();

    DateTimeAdapter().write(binaryWriter, now);
    verify(binaryWriter.writeInt(now.microsecondsSinceEpoch));
  });
}
