import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/buffered_file_writer.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<Box> openBoxInternal(
    HiveImpl hive, String name, bool lazy, BoxOptions options) async {
  var file = await findHiveFileAndCleanUp(name, hive.path);

  CryptoHelper crypto;
  if (options.encrypted) {
    crypto = CryptoHelper(Uint8List.fromList(options.encryptionKey));
  }
  var syncedFile = SyncedFile(file.path);
  await syncedFile.open();

  var backend = StorageBackendVm(syncedFile, crypto);
  BoxBase box;
  if (lazy) {
    box = LazyBoxImpl(hive, name, options, backend);
  } else {
    box = BoxImpl(hive, name, options, backend);
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
  bool supportsCompaction = true;

  @override
  Future<int> initialize(
      Map<dynamic, BoxEntry> entries, bool lazy, bool crashRecovery) async {
    var frames = <Frame>[];
    int recoveryOffset;
    if (!lazy) {
      recoveryOffset =
          await _helper.framesFromFile(path, frames, _registry, _crypto);
    } else {
      recoveryOffset = await _helper.keysFromFile(path, frames, _crypto);
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
  Future<dynamic> readValue(dynamic key, int offset, int length) async {
    var bytes = await _file.readAt(offset, length);
    var frame = Frame.fromBytes(bytes, _registry, _crypto);
    return frame.value;
  }

  @override
  Future<Map<dynamic, dynamic>> readAll() async {
    var frames = <Frame>[];
    await _file.writeLock.synchronized(() {
      return _helper.framesFromFile(path, frames, _registry, _crypto);
    });

    var map = <dynamic, dynamic>{};
    for (var frame in frames) {
      map[frame.key] = frame.value;
    }
    return map;
  }

  @override
  Future<void> writeFrame(Frame frame, BoxEntry entry) async {
    var bytes = frame.toBytes(true, _registry, _crypto);
    if (entry != null) {
      entry.offset = await _file.write(bytes);
      entry.length = bytes.length;
    }
  }

  @override
  Future<void> writeFrames(
      List<Frame> frames, Iterable<BoxEntry> entries) async {
    var bytes = BytesBuilder(copy: false);
    var lengths = <int>[];
    for (var frame in frames) {
      var frameBytes = frame.toBytes(true, _registry, _crypto);
      bytes.add(frameBytes);
      lengths.add(frameBytes.length);
    }

    var offset = await _file.write(bytes.toBytes());

    if (entries != null) {
      var i = 0;
      for (var entry in entries) {
        entry.offset = offset;
        entry.length = lengths[i++];
        offset += entry.length;
      }
    }
  }

  @override
  Future<Map<dynamic, BoxEntry>> compact(Map<dynamic, BoxEntry> entries) async {
    var boxRaf = await File(path).open();
    var reader = BufferedFileReader(boxRaf);

    var compactFile = File('${p.withoutExtension(path)}.hivec');
    var compactRaf = await compactFile.open(mode: FileMode.write);
    var writer = BufferedFileWriter(compactRaf);

    Map<dynamic, BoxEntry> newEntries;
    try {
      await _file.readLock.synchronized(() {
        return _file.writeLock.synchronized(() async {
          newEntries = await performCompaction(entries, reader, writer);
        });
      });
    } finally {
      await boxRaf.close();
      await compactRaf.close();
    }

    await _file.close();
    await compactFile.rename(path);
    await _file.open();
    return newEntries;
  }

  @visibleForTesting
  Future<Map<dynamic, BoxEntry>> performCompaction(
    Map<dynamic, BoxEntry> entries,
    BufferedFileReader reader,
    BufferedFileWriter writer,
  ) async {
    var newEntries = HashMap<dynamic, BoxEntry>();
    var compactOffset = 0;
    for (var key in entries.keys) {
      var entry = entries[key];
      if (entry.offset != reader.offset) {
        await reader.skip(entry.offset - reader.offset);
      }
      var frameBytes = await reader.read(entry.length);
      if (frameBytes.length != entry.length) {
        throw HiveError('Could not compact box: Unexpected EOF.');
      }
      await writer.write(frameBytes);

      newEntries[key] = BoxEntry(entry.value, compactOffset, entry.length);
      compactOffset += entry.length;
    }
    await writer.flush();

    return newEntries;
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
