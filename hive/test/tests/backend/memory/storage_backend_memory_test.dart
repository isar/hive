import 'dart:typed_data';

import 'package:hive/src/backend/stub/storage_backend_memory.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

import '../../common.dart';
import '../../mocks.dart';

void main() {
  group('StorageBackendMemory', () {
    test('.path is null', () {
      var backend = StorageBackendMemory(null, null);
      expect(backend.path, null);
    });

    test('.supportsCompaction is false', () {
      var backend = StorageBackendMemory(null, null);
      expect(backend.supportsCompaction, false);
    });

    group('.initialize()', () {
      test('throws if frames cannot be decoded', () {
        var bytes = Uint8List.fromList([1, 2, 3, 4]);
        var backend = StorageBackendMemory(bytes, null);
        expect(
          () => backend.initialize(
              TypeRegistryImpl.nullImpl, KeystoreFake(), false),
          throwsHiveError('Wrong checksum'),
        );
      });
    });

    test('.readValue() returns previously stored value', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.initialize(
          TypeRegistryImpl.nullImpl, MockKeystore(), false);
      var testFrame = Frame('key', 'val');
      var frameBytes = getFrameBytes([testFrame]);
      testFrame.length = frameBytes.lengthInBytes;
      testFrame.offset = 0;
      await backend.writeFrames([testFrame]);
      expect(
          await backend.readValue(
              Frame('key', 'key', offset: 0, length: frameBytes.lengthInBytes)),
          'val');
    });

    test('.writeFrames() writes data', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.initialize(
          TypeRegistryImpl.nullImpl, MockKeystore(), false);
      await backend.writeFrames([Frame('key', 'val')]);
    });

    test('.compact() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(() => backend.compact([]), throwsUnsupportedError);
    });

    test('.deleteFromDisk() does not throw', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.deleteFromDisk();
    });

    test('.clear() does not throw', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.clear();
    });

    test('.close() does not throw', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.close();
    });

    test('.flush() does nothing', () async {
      var backend = StorageBackendMemory(null, null);
      await backend.flush();
    });
  });
}

Uint8List getFrameBytes(Iterable<Frame> frames) {
  var writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
  for (var frame in frames) {
    writer.writeFrame(frame);
  }
  return writer.toBytes();
}
