import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/frame.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'box_impl.dart';

Future<BoxImpl> openBox(HiveImpl hive, String name, BoxOptions options) async {
  var file = await findHiveFileAndCleanUp(name, hive.path);

  var hiveFile = SyncedFile(file.path);
  await hiveFile.open();

  var box = BoxImplVm(hive, name, options, hiveFile);
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
    print("Restoring compacted file.");
    var newPath = p.setExtension(compactedFile.path, '.hive');
    return await compactedFile.rename(newPath);
  } else {
    hiveFile = File(p.join(hivePath, '$boxName.hive'));
    await hiveFile.create();
    return hiveFile;
  }
}

class ValueEntry {
  final dynamic value;
  final int offset;
  final int length;

  ValueEntry(this.value, this.offset, this.length);

  ValueEntry withOffset(int offset) {
    return ValueEntry(value, offset, length);
  }
}

class BoxImplVm extends BoxImpl {
  static const hiveFileVersion = 1;
  static const deletedBytesRatio = 0.15;
  static const deletedBytesThreshold = 25000;

  final SyncedFile _hiveFile;

  Map<String, ValueEntry> _entries;

  int _deletedBytes = 0;
  int _totalBytes = 0;

  @visibleForTesting
  BoxImplVm(HiveImpl hive, String name, BoxOptions options, this._hiveFile)
      : _entries = HashMap<String, ValueEntry>(),
        super(hive, name, options);

  @visibleForTesting
  BoxImplVm.debugEntries(HiveImpl hive, String name, BoxOptions options,
      this._hiveFile, this._entries)
      : super(hive, name, options);

  @override
  String get path => _hiveFile.path;

  Future<void> initialize() async {
    var hiveFile = File(_hiveFile.path);
    List<Frame> frames;
    if (options.inMemory) {
      frames = await readFramesFromFile(hiveFile, this, decryptor);
    } else {
      frames = await readFrameKeysFromFile(hiveFile, this);
    }
    var offset = 0;
    for (var frame in frames) {
      var key = frame.key;
      if (!frame.deleted) {
        var previousEntry = _entries[key];
        if (previousEntry != null) {
          _deletedBytes += previousEntry.length;
        }
        _entries[key] = ValueEntry(frame.value, offset, frame.length);
      } else {
        var removedFrame = _entries.remove(key);
        if (removedFrame != null) {
          _deletedBytes += frame.length;
          _deletedBytes += removedFrame.length;
        }
      }

      _totalBytes += frame.length;
      offset += frame.length;
    }
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) {
    checkOpen();
    checkKey(key);

    var entry = _entries[key];
    if (entry == null) return Future.value(defaultValue);
    if (entry.value != null) return Future.value(entry.value);

    return _hiveFile.syncRead((file) async {
      await file.setReadPosition(entry.offset);
      var frame = await Frame.fromBytes(file.read, this, true, decryptor);
      return frame.value;
    });
  }

  @override
  Future operator [](String key) {
    return get(key);
  }

  @override
  Future put(String key, dynamic value) async {
    checkOpen();
    checkKey(key);

    var frame = Frame(key, value);
    var entry = await writeFrame(frame);

    var previousEntry = _entries[key];
    if (previousEntry != null) {
      _deletedBytes += previousEntry.length;
    }

    _entries[key] = entry;
    _totalBytes += entry.length;

    await performCompactationIfNeeded();

    notifyChange(key, value, false);
  }

  @override
  Future putAll(Map<String, dynamic> kvPairs) async {
    if (kvPairs.isEmpty) {
      return;
    }
    var frames = List<Frame>();
    kvPairs.forEach((key, val) {
      frames.add(Frame(key, val));
    });
    var entries = await writeFrames(frames);
    for (int i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var previousEntry = _entries[frame.key];
      if (previousEntry != null) {
        _deletedBytes += previousEntry.length;
      }

      var entry = entries[i];
      _entries[frame.key] = entry;
      _totalBytes += entry.length;
    }

    await performCompactationIfNeeded();

    kvPairs.forEach((k, v) {
      notifyChange(k, v, false);
    });
  }

  @override
  bool has(String key) {
    checkOpen();
    checkKey(key);
    return _entries.containsKey(key);
  }

  @override
  Future<bool> delete(String key) async {
    checkOpen();
    checkKey(key);
    if (_entries.containsKey(key)) {
      var entry = await writeFrame(Frame.tombstone(key));
      var deletedEntry = _entries.remove(key);
      _deletedBytes += entry.length + deletedEntry.length;
      _totalBytes += entry.length;
      await performCompactationIfNeeded();

      notifyChange(key, null, true);
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<List<bool>> deleteAll(Iterable<String> keysToDelete) async {
    var tombstoneFrames = List<Frame>();
    var result = List<bool>(keysToDelete.length);
    var i = 0;
    for (var key in keysToDelete) {
      if (!_entries.containsKey(key)) {
        result[i++] = false;
      } else {
        tombstoneFrames.add(Frame.tombstone(key));
        result[i++] = true;
      }
    }

    if (tombstoneFrames.isEmpty) {
      return [];
    }

    var tombstoneEntries = await writeFrames(tombstoneFrames);

    for (var frame in tombstoneFrames) {
      var deletedEntry = _entries.remove(frame.key);
      _deletedBytes += deletedEntry.length;
    }

    for (var tombstoneEntry in tombstoneEntries) {
      _totalBytes += tombstoneEntry.length;
      _deletedBytes += tombstoneEntry.length;
    }

    await performCompactationIfNeeded();

    for (var frame in tombstoneFrames) {
      notifyChange(frame.key, null, true);
    }

    return result;
  }

  @visibleForTesting
  Future<ValueEntry> writeFrame(Frame frame) async {
    var bytes = frame.toBytes(this, true, encryptor);

    var offset = await _hiveFile.write(bytes); // Append to file
    if (options.inMemory) {
      return ValueEntry(frame.value, offset, bytes.length);
    } else {
      return ValueEntry(null, offset, bytes.length);
    }
  }

  @visibleForTesting
  Future<List<ValueEntry>> writeFrames(List<Frame> frames) async {
    var bytes = BytesBuilder(copy: false);
    var frameLengths = List<int>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frameBytes = frames[i].toBytes(this, true, encryptor);
      bytes.add(frameBytes);
      frameLengths[i] = frameBytes.length;
    }

    var offset = await _hiveFile.write(bytes.toBytes()); // Append to file

    var keyEntries = List<ValueEntry>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var frameLength = frameLengths[i];
      if (options.inMemory) {
        keyEntries[i] = ValueEntry(frame.value, offset, frameLength);
      } else {
        keyEntries[i] = ValueEntry(null, offset, frameLength);
      }
      offset += frameLength;
    }

    return keyEntries;
  }

  @override
  Iterable<String> allKeys() {
    checkOpen();
    return _entries.keys;
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    checkOpen();

    if (options.inMemory) {
      return _entries.map((k, e) => MapEntry(k, e.value));
    }

    var map = Map<String, dynamic>();
    await _hiveFile.syncWrite((file) async {
      var frames =
          await readFramesFromFile(File(_hiveFile.path), this, decryptor);
      for (var frame in frames) {
        map[frame.key] = frame.value;
      }
    });

    return map;
  }

  @visibleForTesting
  Future performCompactationIfNeeded() {
    if (_deletedBytes > deletedBytesThreshold) {
      if (_deletedBytes / _totalBytes > deletedBytesRatio) {
        return compact();
      }
    }

    return Future.value();
  }

  @override
  Future compact() async {
    checkOpen();
    await _hiveFile.syncReadWrite((syncedHiveFile) async {
      var hiveFile = File(syncedHiveFile.path);

      var compactWriter = BinaryWriterImpl(this);
      var bufferedHiveFile = await BufferedFileReader.fromFile(hiveFile);
      var compactFilePath = p.join(p.dirname(hiveFile.path), '$name.hivec');
      var compactFile = await File(compactFilePath).open(mode: FileMode.write);

      var compactOffset = 0;
      var newKeys = LinkedHashMap<String, ValueEntry>();
      try {
        for (var key in _entries.keys) {
          var entry = _entries[key];
          if (entry.offset != bufferedHiveFile.offset) {
            await bufferedHiveFile.skip(entry.offset - bufferedHiveFile.offset);
          }
          var frameBytes = await bufferedHiveFile.read(entry.length);
          if (frameBytes.length != entry.length) {
            throw HiveError.corrupted(
                name, "Could not compact box: Unexpected EOF.");
          }
          compactWriter.writeBytes(frameBytes);

          if (compactWriter.writtenBytes > 10000) {
            await compactFile.writeFrom(compactWriter.outputAndClear());
          }
          newKeys[key] = entry.withOffset(compactOffset);
          compactOffset += entry.length;
        }
        await compactFile.writeFrom(compactWriter.outputAndClear());
      } finally {
        await bufferedHiveFile.close();
        await compactFile.close();
      }

      await syncedHiveFile.close();
      await File(compactFile.path).rename(hiveFile.path);
      _entries = newKeys;

      _totalBytes = compactOffset;
      _deletedBytes = 0;
    });

    await _hiveFile.open();
  }

  @override
  Future<int> clear() async {
    checkOpen();

    var count = _entries.length;
    if (count == 0) return 0;

    for (var key in _entries.keys) {
      notifyChange(key, null, true);
    }

    await _hiveFile.truncate(0);
    _entries.clear();

    return count;
  }

  @override
  Future close({bool compact = false}) async {
    if (!isOpen) return;
    if (compact) {
      await this.compact();
    }
    await super.close(compact: compact);
    _entries = null;
    await _hiveFile.close();
  }

  @override
  Future deleteFromDisk() async {
    checkOpen();
    _entries = null;
    await super.deleteFromDisk();
    await _hiveFile.delete();
  }

  @visibleForTesting
  Map<String, ValueEntry> get debugKeys => _entries;

  @visibleForTesting
  int get debugDeletedBytes => _deletedBytes;

  @visibleForTesting
  int get debugTotalBytes => _totalBytes;
}
