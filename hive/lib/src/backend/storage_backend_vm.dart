import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/buffered_file_writer.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<StorageBackend> openBackend(
    HiveInterface hive, String name, CryptoHelper crypto) async {
  var file = await findHiveFileAndCleanUp(name, hive.path);

  var syncedFile = SyncedFile(file.path);
  await syncedFile.open();

  return StorageBackendVm(syncedFile, crypto);
}

@visibleForTesting
Future<File> findHiveFileAndCleanUp(String boxName, String hivePath) async {
  File hiveFile;
  File compactedFile;
  var dir = Directory(hivePath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  var files = await dir.list(followLinks: false).toList();
  for (var file in files) {
    if (file is File) {
      if (file.path.endsWith('$boxName.hive')) {
        hiveFile = file;
      } else if (file.path.endsWith('$boxName.hivec')) {
        compactedFile = file;
      }
    }
  }

  if (hiveFile != null) {
    if (compactedFile != null) {
      await compactedFile.delete();
    }
    return hiveFile;
  } else if (compactedFile != null) {
    print('Restoring compacted file.');
    var newPath = p.setExtension(compactedFile.path, '.hive');
    return await compactedFile.rename(newPath);
  } else {
    hiveFile = File(p.join(hivePath, '$boxName.hive'));
    await hiveFile.create();
    return hiveFile;
  }
}

class StorageBackendVm extends StorageBackend {
  final CryptoHelper _crypto;
  final SyncedFile _file;
  final FrameIoHelper _helper;

  TypeRegistry _registry;

  StorageBackendVm(this._file, this._crypto) : _helper = FrameIoHelper();

  StorageBackendVm.debug(this._file, this._crypto, this._helper);

  @override
  String get path => _file.path;

  @override
  bool supportsCompaction = true;

  @override
  Future<void> initialize(TypeRegistry registry, Keystore keystore, bool lazy,
      bool crashRecovery) async {
    _registry = registry;
    var frames = <Frame>[];
    int recoveryOffset;
    if (!lazy) {
      recoveryOffset =
          await _helper.framesFromFile(path, frames, _registry, _crypto);
    } else {
      recoveryOffset = await _helper.keysFromFile(path, frames, _crypto);
    }

    if (recoveryOffset != -1) {
      if (crashRecovery) {
        print('Recovering corrupted box.');
        await _file.truncate(recoveryOffset);
      } else {
        throw HiveError('Wrong checksum in hive file. Box may be corrupted.');
      }
    }

    var offset = 0;
    for (var frame in frames) {
      if (!frame.deleted) {
        frame.offset = offset;
        keystore.add(frame);
      } else {
        keystore.delete(frame.key);
      }
      offset += frame.length;
    }
  }

  @override
  Future<dynamic> readValue(Frame frame) async {
    var bytes = await _file.readAt(frame.offset, frame.length);
    var readFrame = Frame.fromBytes(bytes, _registry, _crypto);
    return readFrame.value;
  }

  @override
  Future<void> writeFrames(List<Frame> frames) async {
    var writer = BinaryWriterImpl(_registry);

    for (var frame in frames) {
      frame.length = frame.toBytes(writer, _crypto);
    }

    var writeOffset = await _file.write(writer.toBytes());

    for (var frame in frames) {
      frame.offset = writeOffset;
      writeOffset += frame.length;
    }
  }

  @override
  Future<List<Frame>> compact(Iterable<Frame> frames) async {
    var boxRaf = await File(path).open();
    var reader = BufferedFileReader(boxRaf);

    var compactFile = File('${p.withoutExtension(path)}.hivec');
    var compactRaf = await compactFile.open(mode: FileMode.write);
    var writer = BufferedFileWriter(compactRaf);

    List<Frame> newFrames;
    try {
      await _file.readLock.synchronized(() {
        return _file.writeLock.synchronized(() async {
          newFrames = await compactInternal(frames, reader, writer);
        });
      });
    } finally {
      await boxRaf.close();
      await compactRaf.close();
    }

    await _file.close();
    await compactFile.rename(path);
    await _file.open();
    return newFrames;
  }

  @visibleForTesting
  Future<List<Frame>> compactInternal(
    Iterable<Frame> frames,
    BufferedFileReader reader,
    BufferedFileWriter writer,
  ) async {
    var sortedFrames = frames.toList();
    sortedFrames.sort((a, b) => a.offset.compareTo(b.offset));

    var newFrames = <Frame>[];
    var compactOffset = 0;
    for (var frame in sortedFrames) {
      if (frame.offset != reader.offset) {
        await reader.skip(frame.offset - reader.offset);
      }
      var frameBytes = await reader.read(frame.length);
      if (frameBytes.length != frame.length) {
        throw HiveError('Could not compact box: Unexpected EOF.');
      }
      await writer.write(frameBytes);

      newFrames.add(Frame(
        frame.key,
        frame.value,
        length: frame.length,
        offset: compactOffset,
      ));
      compactOffset += frame.length;
    }
    await writer.flush();

    return newFrames;
  }

  @override
  Future<void> clear() {
    return _file.truncate(0);
  }

  @override
  Future<void> close() {
    return _file.close();
  }

  @override
  Future<void> deleteFromDisk() {
    return _file.delete();
  }
}
