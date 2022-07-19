import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/backend/stub/random_access_buffer.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';

/// In-memory storage backend
///
/// This storage memory uses the [RandomAccessBuffer] which is an abstraction
/// for managing data in [Uint8List] as a mean of storage. Data will not be
/// persisted and is lost on close. Data is not stored, is highly volatile
/// and does not survive a page refresh.
class StorageBackendMemory extends StorageBackend {
  late final RandomAccessBuffer _randomAccessBuffer;

  final HiveCipher? _cipher;

  TypeRegistry? _typeRegistry;

  /// Default constructor for the [StorageBackendMemory]
  ///
  /// If needed, provide a [Uint8List] with already existing bytes and the
  /// corresponding [initialOffset]. For encryption, provide a [_cipher].
  StorageBackendMemory(Uint8List? bytes, this._cipher,
      [int initialOffset = 0]) {
    _randomAccessBuffer =
        RandomAccessBuffer(bytes, initialOffset: initialOffset);
  }

  /// An in-memory storage has no path
  @override
  final path = null;

  @override
  final bool supportsCompaction = false;

  @override
  Future<void> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    _typeRegistry = registry;
    await _randomAccessBuffer.recoveryCheck(registry, keystore, _cipher);
  }

  @override
  Future<dynamic> readValue(Frame frame) async {
    return _randomAccessBuffer.read(frame, _typeRegistry!, _cipher);
  }

  @override
  Future<void> writeFrames(List<Frame> frames) {
    return _randomAccessBuffer.write(frames, _typeRegistry!, _cipher);
  }

  @override
  Future<void> compact(Iterable<Frame> frames) {
    throw UnsupportedError('This operation is unsupported for memory boxes.');
  }

  @override
  Future<void> clear() {
    return _randomAccessBuffer.clear();
  }

  @override
  Future<void> close() {
    return _randomAccessBuffer.clear();
  }

  @override
  Future<void> deleteFromDisk() {
    return _randomAccessBuffer.clear();
  }

  /// Nothing to flush to disk as we act directly in-memory
  @override
  Future<void> flush() => Future.value();
}
