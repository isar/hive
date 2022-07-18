import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/stub/random_access_buffer.dart';
import 'package:hive/src/backend/vm/read_write_sync.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/binary/frame_helper.dart';
import 'package:hive/src/box/keystore.dart';

/// Implementation of [RandomAccessBuffer]
///
/// Provides simplified access to raw [Uint8List] for storing
/// [Frame] data. For main usage in [StorageBackendMemory].
class RandomAccessBufferImpl implements RandomAccessBuffer {
  final ReadWriteSync _sync;

  final FrameHelper _frameHelper;

  Uint8List _bytes;

  int _writeOffset;

  RandomAccessBufferImpl(Uint8List? bytes, {int initialOffset = 0})
      : _bytes = bytes ?? Uint8List(0),
        _sync = ReadWriteSync(),
        _writeOffset = initialOffset,
        _frameHelper = FrameHelper();

  @override
  int get length => _bytes.lengthInBytes;

  @override
  int get writeOffset => _writeOffset;

  @override
  Future<dynamic> read(
      Frame frame, TypeRegistry typeRegistry, HiveCipher? cipher) {
    return _sync.syncRead(() async {
      var bytes = _bytes.sublist(frame.offset, frame.offset + frame.length!);
      var reader = BinaryReaderImpl(bytes, typeRegistry);
      var readFrame = reader.readFrame(cipher: cipher, lazy: false);

      if (readFrame == null) {
        throw HiveError('Could not read value from box. '
            'Maybe your box is corrupted.');
      }

      return readFrame.value;
    });
  }

  @override
  Future<void> write(
      List<Frame> frames, TypeRegistry typeRegistry, HiveCipher? cipher) {
    return _sync.syncWrite(() async {
      var writer = BinaryWriterImpl(typeRegistry);

      for (var frame in frames) {
        frame.length = writer.writeFrame(frame, cipher: cipher);
      }

      var b = BytesBuilder();
      b.add(_bytes);
      b.add(writer.toBytes());
      _bytes = b.toBytes();

      for (var frame in frames) {
        frame.offset = _writeOffset;
        _writeOffset += frame.length!;
      }
    });
  }

  @override
  void recoveryCheck(
      TypeRegistry typeRegistry, Keystore? keystore, HiveCipher? cipher) {
    var recoveryOffset = _frameHelper.framesFromBytes(
      _bytes,
      keystore,
      typeRegistry,
      cipher,
    );

    if (recoveryOffset != -1) {
      throw HiveError('Wrong checksum in bytes. Box may be corrupted.');
    }

    _writeOffset = _bytes.offsetInBytes;
  }

  @override
  Future<void> clear() async {
    return _sync.syncReadWrite(() async {
      _bytes = Uint8List(0);
      _writeOffset = 0;
    });
  }
}
