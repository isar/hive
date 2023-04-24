import 'package:hive/src/backend/stub/random_access_buffer.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

void main() {
  group('RandomAccessBuffer', () {
    test('empty random access buffer', () {
      final randomAccessBuffer = RandomAccessBuffer(null);
      expect(randomAccessBuffer.length, 0);
      expect(randomAccessBuffer.writeOffset, 0);
    });

    test('write() writes to random access buffer', () async {
      final typeRegistry = TypeRegistryImpl.nullImpl;

      final randomAccessBuffer = RandomAccessBuffer(null);
      randomAccessBuffer.recoveryCheck(typeRegistry, null, null);

      final frame = Frame("abc", "123");
      await randomAccessBuffer.write([frame], typeRegistry, null);

      expect(randomAccessBuffer.length, getFrameBytes([frame]));
      expect(randomAccessBuffer.writeOffset, getFrameBytes([frame]));
    });

    test('read() reads data from random access buffer', () async {
      final typeRegistry = TypeRegistryImpl.nullImpl;

      final randomAccessBuffer = RandomAccessBuffer(null);
      randomAccessBuffer.recoveryCheck(typeRegistry, null, null);

      final saveFrame = Frame("abc", "123", offset: 0, length: 3);
      await randomAccessBuffer.write([saveFrame], typeRegistry, null);

      expect(randomAccessBuffer.length, getFrameBytes([saveFrame]));
      expect(randomAccessBuffer.writeOffset, getFrameBytes([saveFrame]));

      final storedValue = await randomAccessBuffer.read(
          Frame("abc", "abc", offset: 0, length: 21), typeRegistry, null);

      expect(storedValue, "123");
    });

    test('clear() resets random access buffer', () async {
      final typeRegistry = TypeRegistryImpl.nullImpl;

      final randomAccessBuffer = RandomAccessBuffer(null);
      randomAccessBuffer.recoveryCheck(typeRegistry, null, null);

      final frame = Frame("abc", "123");
      await randomAccessBuffer.write([frame], typeRegistry, null);

      expect(randomAccessBuffer.length, getFrameBytes([frame]));
      expect(randomAccessBuffer.writeOffset, getFrameBytes([frame]));

      await randomAccessBuffer.clear();

      expect(randomAccessBuffer.length, 0);
      expect(randomAccessBuffer.writeOffset, 0);
    });
  });
}

int getFrameBytes(Iterable<Frame> frames) {
  var writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
  for (var frame in frames) {
    writer.writeFrame(frame);
  }
  return writer.toBytes().lengthInBytes;
}
