import 'package:hive/src/adapters/uint8_list_adapter.dart';
import 'package:hive/src/hive_instance_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  test("read", () {
    var bytes = HiveInstanceImpl().generateSecureKey();
    var binaryReader = BinaryReaderMock();
    when(binaryReader.readWord()).thenReturn(bytes.length);
    when(binaryReader.readBytes(bytes.length)).thenReturn(bytes);

    var readBytes = Uint8ListAdapter().read(binaryReader);
    verifyInOrder([
      binaryReader.readWord(),
      binaryReader.readBytes(bytes.length),
    ]);
    expect(readBytes, bytes);
  });

  test("write", () {
    var bytes = HiveInstanceImpl().generateSecureKey();
    var binaryWriter = BinaryWriterMock();

    Uint8ListAdapter().write(binaryWriter, bytes);
    verifyInOrder([
      binaryWriter.writeWord(bytes.length),
      binaryWriter.writeBytes(bytes),
    ]);
  });
}
