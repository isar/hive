import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/util/lock.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

Future<BoxImpl> openBox(
    HiveInterface hive, String name, BoxOptions options) async {
  var file = await findHiveFileAndCleanUp(name, hive.path);

  CryptoHelper crypto;
  if (options.encrypted) {
    crypto = CryptoHelper(Uint8List.fromList(options.encryptionKey));
  }

  var backend = StorageBackendVm(file.path, crypto);
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
  @override
  final String path;
  final Lock _readLock = Lock.newLock();
  final Lock _writeLock = Lock.newLock();
  final CryptoHelper _crypto;

  TypeRegistry _registry;
  RandomAccessFile _readFile;
  RandomAccessFile _writeFile;
  int _writeOffset = 0;

  StorageBackendVm(this.path, this._crypto);

  Future<dynamic> readValue(String key, int offset) {
    return _readLock.synchronized(() async {
      await _readFile.setPosition(offset);
      var frame = await Frame.fromBytes(
          _readFile.read, _registry, true, _crypto.decryptor);
      return frame.value;
    });
  }

  Future<Map<String, dynamic>> readAll(Iterable<String> keys) {
    var map = Map<String, dynamic>();
    return _writeLock.synchronized(() async {
      var frames = await readFramesFromFile(path, _registry, _crypto.decryptor);
      for (var frame in frames) {
        map[frame.key] = frame.value;
      }

      return map;
    });
  }

  _openFiles() async {
    var file = File(path);
    _readFile = await file.open(mode: FileMode.read);
    _writeFile = await file.open(mode: FileMode.append);
  }

  _closeFiles() async {
    await _readFile.close();
    await _writeFile.close();
  }

  @override
  Future<int> initialize(Map<String, BoxEntry> entries, bool cache) async {
    await _openFiles();

    List<Frame> frames;
    if (cache) {
      frames = await readFramesFromFile(path, _registry, _crypto.decryptor);
    } else {
      frames = await readFrameKeysFromFile(path);
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

    _writeOffset = offset;

    return deletedEntries;
  }

  @visibleForTesting
  Future<BoxEntry> writeFrame(Frame frame, bool cache) async {
    var bytes = frame.toBytes(_registry, true, _crypto.encryptor);

    await _writeLock.synchronized(() {
      return _writeFile.writeFrom(bytes); // Append to file
    });

    var value = cache ? frame.value : null;
    var entry = BoxEntry(value, _writeOffset, bytes.length);
    _writeOffset += bytes.length;
    return entry;
  }

  @visibleForTesting
  Future<List<BoxEntry>> writeFrames(List<Frame> frames, bool cache) async {
    var bytes = BytesBuilder(copy: false);
    var frameLengths = List<int>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frameBytes = frames[i].toBytes(_registry, true, _crypto.encryptor);
      bytes.add(frameBytes);
      frameLengths[i] = frameBytes.length;
    }

    await _writeLock.synchronized(() {
      return _writeFile.writeFrom(bytes.toBytes()); // Append to file
    });

    var keyEntries = List<BoxEntry>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var frameLength = frameLengths[i];
      var value = cache ? frame.value : null;
      keyEntries[i] = BoxEntry(value, _writeOffset, frameLength);
      _writeOffset += frameLength;
    }

    return keyEntries;
  }

  Future<Map<String, BoxEntry>> compact(Map<String, BoxEntry> entries) {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() async {
        var reader = await BufferedFileReader.fromFile(path);
        var writer = BinaryWriterImpl(_registry);
        var compactPath = p.withoutExtension(path) + '.hivec';
        var compactFile = await File(compactPath).open(mode: FileMode.write);

        var compactOffset = 0;
        var newEntries = HashMap<String, BoxEntry>();
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
            writer.writeBytes(frameBytes);

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

        await _closeFiles();
        await File(compactFile.path).rename(path);
        await _openFiles();
        return newEntries;
      });
    });
  }

  @override
  Future clear() {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() async {
        await _writeFile.truncate(0);
        _writeOffset = 0;
      });
    });
  }

  @override
  Future close() {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() async {
        await _closeFiles();
      });
    });
  }

  @override
  Future deleteFromDisk() {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() {
        return File(path).delete();
      });
    });
  }
}
