import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/cached_box.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/lazy_box.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<Box> openBox(HiveImpl hive, String name, BoxOptions options) async {
  var file = await findHiveFileAndCleanUp(name, hive.path);

  CryptoHelper crypto;
  if (options.encrypted) {
    crypto = CryptoHelper(Uint8List.fromList(options.encryptionKey));
  }
  var syncedFile = SyncedFile(file.path);
  await syncedFile.open();

  var backend = StorageBackendVm(syncedFile, crypto);
  BoxBase box;
  if (options.lazy) {
    box = LazyBox(hive, name, options, backend);
  } else {
    box = CachedBox(hive, name, options, backend);
  }
  backend._registry = box;

  await box.initialize();

  return box;
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
  Future<int> initialize(
      Map<String, BoxEntry> entries, bool lazy, bool crashRecovery) async {
    var frames = <Frame>[];
    int recoveryOffset;
    if (!lazy) {
      recoveryOffset =
          await _helper.readFramesFromFile(path, frames, _registry, _crypto);
    } else {
      recoveryOffset =
          await _helper.readFrameKeysFromFile(path, frames, _crypto);
    }

    if (recoveryOffset != null) {
      if (crashRecovery) {
        await _file.truncate(recoveryOffset);
      } else {
        throw HiveError('Wrong checksum in hive file. Box may be corrupted.');
      }
    }

    var offset = 0;
    var deletedEntries = 0;
    for (var frame in frames) {
      var key = frame.key;
      if (!frame.deleted) {
        if (entries.containsKey(key)) {
          deletedEntries++;
        }
        entries[key] = BoxEntry(frame.value, offset, frame.length);
      } else {
        if (entries.remove(key) != null) {
          deletedEntries++;
        }
      }

      offset += frame.length;
    }

    return deletedEntries;
  }

  @override
  Future<dynamic> readValue(String key, int offset, int length) async {
    var bytes = await _file.readAt(offset, length);
    var frame = Frame.fromBytes(bytes, _registry, _crypto);
    return frame.value;
  }

  @override
  Future<Map<String, dynamic>> readAll() async {
    var frames = <Frame>[];
    await _file.writeLock.synchronized(() {
      return _helper.readFramesFromFile(path, frames, _registry, _crypto);
    });

    var map = <String, dynamic>{};
    for (var frame in frames) {
      map[frame.key] = frame.value;
    }
    return map;
  }

  @override
  Future writeFrame(Frame frame, BoxEntry entry) async {
    var bytes = frame.toBytes(true, _registry, _crypto);
    entry?.offset = await _file.write(bytes);
    entry?.length = bytes.length;
  }

  @override
  Future writeFrames(List<Frame> frames, Iterable<BoxEntry> entries) async {
    var bytes = BytesBuilder(copy: false);
    var lengths = List<int>(frames.length);
    var i = 0;
    for (var frame in frames) {
      var frameBytes = frame.toBytes(true, _registry, _crypto);
      bytes.add(frameBytes);
      lengths[i++] = frameBytes.length;
    }

    var offset = await _file.write(bytes.toBytes());

    i = 0;
    for (var entry in entries) {
      var length = lengths[i++];
      entry?.offset = offset;
      entry?.length = length;
      offset += length;
    }
  }

  @override
  Future<Map<String, BoxEntry>> compact(Map<String, BoxEntry> entries) async {
    var compactPath = '${p.withoutExtension(path)}.hivec';
    var compactFile = await File(compactPath).open(mode: FileMode.write);

    var newEntries = HashMap<String, BoxEntry>();

    await _file.readLock.synchronized(() {
      return _file.writeLock.synchronized(() async {
        var reader = await BufferedFileReader.fromFile(path);
        var writer = BinaryWriterImpl(_registry);

        var compactOffset = 0;

        try {
          for (var key in entries.keys) {
            var entry = entries[key];
            if (entry.offset != reader.offset) {
              await reader.skip(entry.offset - reader.offset);
            }
            var frameBytes = await reader.read(entry.length);
            if (frameBytes.length != entry.length) {
              throw HiveError('Could not compact box: Unexpected EOF.');
            }
            writer.writeByteList(frameBytes, writeLength: false);

            if (writer.writtenBytes > 10000) {
              await compactFile.writeFrom(writer.outputAndClear());
            }
            newEntries[key] =
                BoxEntry(entry.value, compactOffset, entry.length);
            compactOffset += entry.length;
          }
          await compactFile.writeFrom(writer.outputAndClear());
        } finally {
          await reader.close();
          await compactFile.close();
        }
      });
    });

    await _file.close();
    await File(compactFile.path).rename(path);
    await _file.open();
    return newEntries;
  }

  @override
  Future clear() {
    return _file.truncate(0);
  }

  @override
  Future close() {
    return _file.close();
  }

  @override
  Future deleteFromDisk() {
    return _file.delete();
  }
}
