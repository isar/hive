import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame_helper.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class FrameIoHelper extends FrameHelper {
  /// Not part of public API
  ///
  /// helps allowing to override this method in tests
  @visibleForTesting
  FutureOr<RandomAccessFile> overridableRAF(RandomAccessFile raf) {
    return raf;
  }

  /// Not part of public API
  ///
  /// helps allowing to override this method in tests
  @visibleForTesting
  Future<Uint8List> overridableReadFile(RandomAccessFile raf) async {
    final previousPosition = await raf.position(); // likely 0 in any case

    final length = await raf.length();
    final bytes = await raf.read(length);

    await raf.setPosition(previousPosition);

    return bytes;
  }

  /// Not part of public API
  Future<int> keysFromFile(
      RandomAccessFile raf, Keystore keystore, HiveCipher? cipher) async {
    // only used for testing override
    final file = await overridableRAF(raf);
    final fileReader = BufferedFileReader(file);

    return await _KeyReader(fileReader).readKeys(keystore, cipher);
  }

  /// Not part of public API
  Future<int> framesFromFile(RandomAccessFile raf, Keystore keystore,
      TypeRegistry registry, HiveCipher? cipher) async {
    // only used for testing override
    final bytes = await overridableReadFile(raf);
    return framesFromBytes(bytes, keystore, registry, cipher);
  }
}

class _KeyReader {
  final BufferedFileReader fileReader;

  late BinaryReaderImpl _reader;

  _KeyReader(this.fileReader);

  Future<int> readKeys(Keystore keystore, HiveCipher? cipher) async {
    await _load(4);
    while (true) {
      var frameOffset = fileReader.offset;

      if (_reader.availableBytes < 4) {
        var available = await _load(4);
        if (available == 0) {
          break;
        } else if (available < 4) {
          return frameOffset;
        }
      }

      var frameLength = _reader.peekUint32();
      if (_reader.availableBytes < frameLength) {
        var available = await _load(frameLength);
        if (available < frameLength) return frameOffset;
      }

      var frame = await _reader.readFrame(
        cipher: cipher,
        lazy: true,
        frameOffset: frameOffset,
      );
      if (frame == null) return frameOffset;

      keystore.insert(frame, notify: false);

      fileReader.skip(frameLength);
    }

    return -1;
  }

  Future<int> _load(int bytes) async {
    var loadedBytes = await fileReader.loadBytes(bytes);
    var buffer = fileReader.peekBytes(loadedBytes);
    _reader = BinaryReaderImpl(buffer, TypeRegistryImpl.nullImpl);

    return loadedBytes;
  }
}
