import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/crypto.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<BoxImpl> openBox(
    HiveInterface hive, String name, BoxOptions options) async {
  var file = await findHiveFileAndCleanUp(name, hive.path);

  Crypto crypto;
  if (options.encrypted) {
    crypto = Crypto(Uint8List.fromList(options.encryptionKey));
  }
  var syncedFile = SyncedFile(file.path);
  var backend = StorageBackendVm(syncedFile, crypto);
  var box = BoxImpl(hive, name, options, backend);
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
    if (file is! File) continue;
    if (file.path.endsWith('$boxName.hive')) {
      hiveFile = file;
    } else if (file.path.endsWith('$boxName.hivec')) {
      compactedFile = file;
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
  final Crypto _crypto;
  final SyncedFile _file;

  TypeRegistry _registry;

  StorageBackendVm(this._file, this._crypto);

  @override
  String get path => _file.path;

  @override
  Future<int> initialize(Map<String, BoxEntry> entries, bool cache) async {
    List<Frame> frames;
    if (cache) {
      frames = await readFramesFromFile(path, _registry, _crypto);
    } else {
      frames = await readFrameKeysFromFile(path, _crypto);
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
  Future<Map<String, dynamic>> readAll(Iterable<String> keys) async {
    var frames = await _file.writeLock.synchronized(() {
      return readFramesFromFile(path, _registry, _crypto);
    });

    var map = Map<String, dynamic>();
    for (var frame in frames) {
      map[frame.key] = frame.value;
    }
    return map;
  }

  @visibleForTesting
  Future<BoxEntry> writeFrame(Frame frame, bool cache) async {
    var bytes = frame.toBytes(true, _registry, _crypto);

    var offset = await _file.write(bytes);

    var value = cache ? frame.value : null;
    return BoxEntry(value, offset, bytes.length);
  }

  @visibleForTesting
  Future<List<BoxEntry>> writeFrames(List<Frame> frames, bool cache) async {
    var bytes = BytesBuilder(copy: false);
    var frameLengths = List<int>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frameBytes = frames[i].toBytes(true, _registry, _crypto);
      bytes.add(frameBytes);
      frameLengths[i] = frameBytes.length;
    }

    var offset = await _file.write(bytes.toBytes());

    var keyEntries = List<BoxEntry>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var frameLength = frameLengths[i];
      var value = cache ? frame.value : null;
      keyEntries[i] = BoxEntry(value, offset, frameLength);
      offset += frameLength;
    }

    return keyEntries;
  }

  Future<Map<String, BoxEntry>> compact(Map<String, BoxEntry> entries) async {
    var compactPath = p.withoutExtension(path) + '.hivec';
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
  Future deleteFromDisk() async {
    await _file.close;
    await File(path).delete();
  }
}
