import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/backend/vm/read_write_sync.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/binary/frame_helper.dart';
import 'package:hive/src/box/keystore.dart';

/// In-memory Storage backend
class StorageBackendMemory extends StorageBackend {
  final HiveCipher? _cipher;

  final ReadWriteSync _sync;

  final FrameHelper _frameHelper;

  Uint8List _bytes;

  TypeRegistry? _typeRegistry;

  int _writeOffset = 0;

  /// Not part of public API
  StorageBackendMemory(Uint8List? bytes, this._cipher)
      : _bytes = bytes ?? Uint8List(0),
        _sync = ReadWriteSync(),
        _frameHelper = FrameHelper();

  @override
  String? get path => null;

  @override
  bool get supportsCompaction => false;

  @override
  Future<void> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    _typeRegistry = registry;

    var recoveryOffset = _frameHelper.framesFromBytes(
      _bytes,
      keystore,
      registry,
      _cipher,
    );

    if (recoveryOffset != -1) {
      throw HiveError('Wrong checksum in bytes. Box may be corrupted.');
    }

    _writeOffset = _bytes.offsetInBytes;
  }

  @override
  Future<dynamic> readValue(Frame frame) {
    return _sync.syncRead(() async {
      var bytes = _bytes.sublist(frame.offset, frame.offset + frame.length!);
      var reader = BinaryReaderImpl(bytes, _typeRegistry!);
      var readFrame = reader.readFrame(cipher: _cipher, lazy: false);

      if (readFrame == null) {
        throw HiveError(
            'Could not read value from box. Maybe your box is corrupted.');
      }

      return readFrame.value;
    });
  }

  @override
  Future<void> writeFrames(List<Frame> frames) {
    return _sync.syncWrite(() async {
      var writer = BinaryWriterImpl(_typeRegistry!);

      for (var frame in frames) {
        frame.length = writer.writeFrame(frame, cipher: _cipher);
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
  Future<void> compact(Iterable<Frame> frames) {
    throw UnsupportedError('This operation is unsupported for memory boxes.');
  }

  @override
  Future<void> clear() {
    return _sync.syncReadWrite(() async {
      _clearMemoryBuffer();
    });
  }

  @override
  Future<void> close() async {
    _clearMemoryBuffer();
  }

  @override
  Future<void> deleteFromDisk() {
    return _sync.syncReadWrite(() async {
      _clearMemoryBuffer();
    });
  }

  /// Nothing to flush to disk as we act directly in-memory
  @override
  Future<void> flush() => Future.value();

  /// Clear the memory buffer and reset the offset
  void _clearMemoryBuffer() {
    _bytes = Uint8List(0);
    _writeOffset = 0;
  }
}
