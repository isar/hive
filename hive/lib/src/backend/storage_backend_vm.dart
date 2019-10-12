import 'dart:async';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/read_write_sync.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/buffered_file_writer.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<StorageBackend> openBackend(HiveInterface hive, String name, bool lazy,
    bool crashRecovery, CryptoHelper crypto) async {
  var dir = Directory(hive.path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  var file = await findHiveFileAndCleanUp(name, dir);
  var lockFile = File(p.join(dir.path, '$name.lock'));

  var backend = StorageBackendVm(file, lockFile, lazy, crashRecovery, crypto);
  await backend.open();
  return backend;
}

@visibleForTesting
Future<File> findHiveFileAndCleanUp(String boxName, Directory dir) async {
  File hiveFile;
  File compactedFile;

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
    hiveFile = File(p.join(dir.path, '$boxName.hive'));
    await hiveFile.create();
    return hiveFile;
  }
}

class StorageBackendVm extends StorageBackend {
  final File file;
  final File lockFile;
  final bool lazy;
  final bool crashRecovery;
  final CryptoHelper crypto;
  final FrameIoHelper helper;

  final ReadWriteSync _sync;

  @visibleForTesting
  RandomAccessFile readRaf;

  @visibleForTesting
  RandomAccessFile writeRaf;

  @visibleForTesting
  RandomAccessFile lockRaf;

  @visibleForTesting
  int writeOffset = 0;

  @visibleForTesting
  TypeRegistry registry;

  StorageBackendVm(
      this.file, this.lockFile, this.lazy, this.crashRecovery, this.crypto)
      : helper = FrameIoHelper(),
        _sync = ReadWriteSync();

  StorageBackendVm.debug(this.file, this.lockFile, this.lazy,
      this.crashRecovery, this.crypto, this.helper, this._sync);

  @override
  String get path => file.path;

  @override
  bool supportsCompaction = true;

  Future open() async {
    readRaf = await file.open();
    writeRaf = await file.open(mode: FileMode.writeOnlyAppend);
    writeOffset = await writeRaf.length();
  }

  @override
  Future<void> initialize(TypeRegistry registry, Keystore keystore) async {
    this.registry = registry;

    lockRaf = await lockFile.open(mode: FileMode.write);
    await lockRaf.lock();

    var frames = <Frame>[];
    int recoveryOffset;
    if (!lazy) {
      recoveryOffset =
          await helper.framesFromFile(path, frames, registry, crypto);
    } else {
      recoveryOffset = await helper.keysFromFile(path, frames, crypto);
    }

    if (recoveryOffset != -1) {
      if (crashRecovery) {
        print('Recovering corrupted box.');
        await writeRaf.truncate(recoveryOffset);
        writeOffset = recoveryOffset;
      } else {
        throw HiveError('Wrong checksum in hive file. Box may be corrupted.');
      }
    }

    var offset = 0;
    for (var frame in frames) {
      frame.offset = offset;
      keystore.insert(frame);
      offset += frame.length;
    }
  }

  @override
  Future<dynamic> readValue(Frame frame) {
    return _sync.syncRead(() async {
      await readRaf.setPosition(frame.offset);
      var bytes = await readRaf.read(frame.length);
      var readFrame = Frame.fromBytes(bytes, registry, crypto);
      return readFrame.value;
    });
  }

  @override
  Future<void> writeFrames(List<Frame> frames) {
    return _sync.syncWrite(() async {
      var writer = BinaryWriterImpl(registry);

      for (var frame in frames) {
        frame.length = frame.toBytes(writer, crypto);
      }

      try {
        await writeRaf.writeFrom(writer.toBytes());
      } catch (e) {
        await writeRaf.setPosition(writeOffset);
        rethrow;
      }

      for (var frame in frames) {
        frame.offset = writeOffset;
        writeOffset += frame.length;
      }
    });
  }

  @override
  Future<void> compact(Iterable<Frame> frames) {
    return _sync.syncReadWrite(() async {
      await readRaf.setPosition(0);
      var reader = BufferedFileReader(readRaf);

      var compactFile = File('${p.withoutExtension(path)}.hivec');
      var compactRaf = await compactFile.open(mode: FileMode.write);
      var writer = BufferedFileWriter(compactRaf);

      var sortedFrames = frames.toList();
      sortedFrames.sort((a, b) => a.offset.compareTo(b.offset));
      try {
        for (var frame in sortedFrames) {
          if (frame.offset == -1) continue;
          if (frame.offset != reader.offset) {
            await reader.skip(frame.offset - reader.offset);
          }
          var frameBytes = await reader.read(frame.length);
          if (frameBytes.length != frame.length) {
            throw HiveError('Could not compact box: Unexpected EOF.');
          }
          await writer.write(frameBytes);
        }
        await writer.flush();
      } finally {
        await compactRaf.close();
      }

      await readRaf.close();
      await writeRaf.close();
      await compactFile.rename(path);
      await open();

      var offset = 0;
      for (var frame in sortedFrames) {
        if (frame.offset == -1) continue;
        frame.offset = offset;
        offset += frame.length;
      }
    });
  }

  @override
  Future<void> clear() {
    return _sync.syncReadWrite(() async {
      await writeRaf.truncate(0);
      await writeRaf.setPosition(0);
      writeOffset = 0;
    });
  }

  Future _closeInternal() async {
    await readRaf.close();
    await writeRaf.close();

    await lockRaf.close();
    await lockFile.delete();
  }

  @override
  Future<void> close() {
    return _sync.syncReadWrite(_closeInternal);
  }

  @override
  Future<void> deleteFromDisk() {
    return _sync.syncReadWrite(() async {
      await _closeInternal();
      await file.delete();
    });
  }
}
