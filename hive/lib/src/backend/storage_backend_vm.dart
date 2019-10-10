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

  var lockFile = File(p.join(dir.path, '$name.lock'));
  var lock = await lockFile.open(mode: FileMode.write);
  await lock.lock();

  var file = await findHiveFileAndCleanUp(name, dir);

  var backend = StorageBackendVm(file, lazy, crashRecovery, crypto, lock);
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
  final bool lazy;
  final bool crashRecovery;
  final CryptoHelper crypto;
  final FrameIoHelper helper;

  final RandomAccessFile _lock;
  final ReadWriteSync _sync;

  RandomAccessFile _readFile;
  RandomAccessFile _writeFile;
  int _writeOffset;
  TypeRegistry _registry;

  StorageBackendVm(
      this.file, this.lazy, this.crashRecovery, this.crypto, this._lock)
      : helper = FrameIoHelper(),
        _sync = ReadWriteSync();

  StorageBackendVm.debug(this.file, this.lazy, this.crashRecovery, this.crypto,
      this.helper, this._lock, this._sync);

  @override
  String get path => file.path;

  @override
  bool supportsCompaction = true;

  Future open() async {
    _readFile = await file.open();
    _writeFile = await file.open(mode: FileMode.writeOnlyAppend);
    _writeOffset = await _writeFile.length();
  }

  @override
  Future<void> initialize(TypeRegistry registry, Keystore keystore) async {
    _registry = registry;
    var frames = <Frame>[];
    int recoveryOffset;
    if (!lazy) {
      recoveryOffset =
          await helper.framesFromFile(path, frames, _registry, crypto);
    } else {
      recoveryOffset = await helper.keysFromFile(path, frames, crypto);
    }

    if (recoveryOffset != -1) {
      if (crashRecovery) {
        print('Recovering corrupted box.');
        await _writeFile.truncate(recoveryOffset);
        _writeOffset = recoveryOffset;
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
      await _readFile.setPosition(frame.offset);
      var bytes = await _readFile.read(frame.length);
      var readFrame = Frame.fromBytes(bytes, _registry, crypto);
      return readFrame.value;
    });
  }

  @override
  Future<void> writeFrames(List<Frame> frames) {
    return _sync.syncWrite(() async {
      var writer = BinaryWriterImpl(_registry);

      for (var frame in frames) {
        frame.length = frame.toBytes(writer, crypto);
      }

      var oldOffset = _writeOffset;
      try {
        await _writeFile.writeFrom(writer.toBytes());
      } catch (e) {
        _writeOffset = oldOffset;
        await _writeFile.setPosition(oldOffset);
        rethrow;
      }

      for (var frame in frames) {
        frame.offset = _writeOffset;
        _writeOffset += frame.length;
      }
    });
  }

  @override
  Future<void> compact(Iterable<Frame> frames) {
    return _sync.syncReadWrite(() async {
      await _readFile.setPosition(0);
      var reader = BufferedFileReader(_readFile);

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

      await _readFile.close();
      await _writeFile.close();
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
      await _writeFile.truncate(0);
      await _writeFile.setPosition(0);
      _writeOffset = 0;
    });
  }

  Future _closeInternal() async {
    await _readFile.close();
    await _writeFile.close();

    var lockFile = File(_lock.path);
    await _lock.close();
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
      await File(path).delete();
    });
  }
}
