import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_memory.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

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
      test('adds decoded frames to keystore', () {
        var frame = Frame('key', 'value', offset: -1, length: 23);
        var deletedFrame = Frame.deleted('deletedKey');
        var writer = BinaryWriterImpl(null);
        frame.toBytes(writer, null);
        deletedFrame.toBytes(writer, null);

        var backend = StorageBackendMemory(writer.toBytes(), null);
        var keystore = KeystoreMock();
        backend.initialize(null, keystore);
        verify(keystore.add(frame));
        verify(keystore.delete(deletedFrame.key));
      });

      test('throws if frames cannot be decoded', () {
        var backend =
            StorageBackendMemory(Uint8List.fromList([1, 2, 3, 4]), null);
        expect(
          () => backend.initialize(null, null),
          throwsHiveError('Wrong checksum'),
        );
      });
    });

    test('.readValue() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(
          () => backend.readValue(Frame('key', 'val')), throwsUnsupportedError);
    });

    test('.compact() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(() => backend.compact([]), throwsUnsupportedError);
    });

    test('.deleteFromDisk() throws UnsupportedError', () {
      var backend = StorageBackendMemory(null, null);
      expect(() => backend.deleteFromDisk(), throwsUnsupportedError);
    });
  });
}
