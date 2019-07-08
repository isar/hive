import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/box_options.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/hive_instance_impl.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/frame.dart';
import 'package:hive/src/io/header.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class KeyEntry {
  final String key;
  final int offset;
  final int length;

  KeyEntry(this.key, this.offset, this.length);

  bool operator ==(o) =>
      o is KeyEntry && o.key == key && o.offset == offset && o.length == length;
  int get hashCode => key.hashCode + offset.hashCode + length.hashCode;
}

class BoxImpl extends TypeRegistryImpl implements Box {
  static const hiveFileVersion = 1;
  static const deletedBytesRatio = 0.15;
  static const deletedBytesThreshold = 10000;

  final HiveInstanceImpl _hive;
  final String name;
  final BoxOptions options;
  final SyncedFile _hiveFile;
  final _streamController = StreamController<BoxEvent>.broadcast();

  Map<String, KeyEntry> _keys;
  bool _open = true;
  CryptoHelper _cryptoHelper;

  int _deletedBytes = 0;
  int _totalBytes = 0;

  @visibleForTesting
  BoxImpl(this._hive, this.name, this.options, this._hiveFile)
      : _keys = LinkedHashMap<String, KeyEntry>(),
        super(_hive);

  @visibleForTesting
  BoxImpl.keysForTest(
      this._hive, this.name, this.options, this._hiveFile, this._keys)
      : super(_hive);

  bool get isOpen => _open;

  static Future<Box> open(HiveInstanceImpl hive, String name, Directory dir,
      BoxOptions options) async {
    var file = await findHiveFileAndCleanUp(name, dir);

    var hiveFile = SyncedFile(file.path);
    await hiveFile.open();

    try {
      var box = BoxImpl(hive, name, options, hiveFile);
      var dataVersion = await box.verifyHeader();
      await box.readKeysFromHiveFile();

      if (options.encryptionKey != null) {
        box._cryptoHelper = CryptoHelper(options.encryptionKey);
      }

      if (dataVersion < options.version && options.migrator != null) {
        await (options.migrator(dataVersion, options.version, box));
        var newHeader =
            Header(hiveFileVersion, options.version, options.encrypted);
        await box.updateHeader(newHeader);
      }

      return box;
    } catch (e) {
      await hiveFile.close();
      rethrow;
    }
  }

  @visibleForTesting
  static Future<File> findHiveFileAndCleanUp(
      String boxName, Directory dir) async {
    File hiveFile;
    File compactedFile;
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
      hiveFile = File(p.join(dir.path, '$boxName.hive'));
      await hiveFile.create();
      return hiveFile;
    }
  }

  void _checkOpen() {
    if (!_open) {
      throw HiveError("Box has already been closed.");
    }
  }

  void _checkKey(String key) {
    _checkOpen();
    if (key == null) {
      throw HiveError("Key must not be null");
    }
  }

  @visibleForTesting
  Future<int> verifyHeader() async {
    var headerBytes = await _hiveFile.read(Header.headerLength);
    Header header;
    if (headerBytes.isEmpty) {
      header = Header(hiveFileVersion, options.version, options.encrypted);
      headerBytes = header.toBytes(keyHash: _cryptoHelper?.keyHash);
      await _hiveFile.write(headerBytes);
    } else if (headerBytes.length >= 8) {
      header = Header.fromBytes(headerBytes, keyHash: _cryptoHelper?.keyHash);
    } else {
      throw HiveError.corrupted(name, "File header could not be verified.");
    }

    if (header.fileVersion != hiveFileVersion) {
      throw HiveError("Unsupported version of Hive file.");
    }

    return header.dataVersion;
  }

  @visibleForTesting
  Future updateHeader(Header header) async {
    var len = _hiveFile.writeOffset;
    await _hiveFile.setWritePosition(0);
    var headerBytes = header.toBytes(keyHash: _cryptoHelper?.keyHash);
    await _hiveFile.write(headerBytes);
    await _hiveFile.setWritePosition(len);
  }

  @visibleForTesting
  Future readKeysFromHiveFile() async {
    var offset = Header.headerLength;
    var stream = Frame.streamAll(
      File(_hiveFile.path),
      this,
      readValue: false,
    );
    await for (var frame in stream) {
      if (frame.error != null) {
        throw HiveError.corrupted(name, "Could not read keys.");
      } else {
        var key = frame.key;
        if (!frame.deleted) {
          var previousEntry = _keys[key];
          if (previousEntry != null) {
            _deletedBytes += previousEntry.length;
          }
          _keys[key] = KeyEntry(frame.key, offset, frame.length);
        } else {
          var removedFrame = _keys.remove(key);
          if (removedFrame != null) {
            _deletedBytes += frame.length;
            _deletedBytes += removedFrame.length;
          }
        }

        _totalBytes += frame.length;
        offset += frame.length;
      }
    }
  }

  @override
  Stream<BoxEvent> watch({String key}) {
    if (key != null) {
      return _streamController.stream.where((it) => it.key == key);
    } else {
      return _streamController.stream;
    }
  }

  @visibleForTesting
  void notifyChange(String key, dynamic value, bool deleted) {
    _streamController.add(BoxEvent(key, value, deleted));
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) async {
    _checkKey(key);

    var entry = _keys[key];
    if (entry == null) return defaultValue;

    var frame = await _hiveFile.syncRead((file) async {
      await file.setReadPosition(entry.offset);
      return await Frame.fromReader(
        (bytes) => file.read(bytes),
        this,
        decryptor: _cryptoHelper?.decryptor,
      );
    });

    return frame.value;
  }

  @override
  Future operator [](String key) {
    return get(key);
  }

  @override
  Future put(String key, dynamic value) async {
    _checkKey(key);

    var frame = Frame(key, value);
    var entry = await writeFrame(frame);

    var previousEntry = _keys[key];
    if (previousEntry != null) {
      _deletedBytes += previousEntry.length;
    }

    _keys[key] = entry;
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
    var keyEntries = await writeFrames(frames);
    for (var entry in keyEntries) {
      var previousEntry = _keys[entry.key];
      if (previousEntry != null) {
        _deletedBytes += previousEntry.length;
      }

      _keys[entry.key] = entry;
      _totalBytes += entry.length;
    }

    await performCompactationIfNeeded();

    kvPairs.forEach((k, v) {
      notifyChange(k, v, false);
    });
  }

  @override
  Future<bool> has(String key) async {
    _checkKey(key);
    return _keys.containsKey(key);
  }

  @override
  Future<bool> delete(String key) async {
    _checkKey(key);
    if (_keys.containsKey(key)) {
      var entry = await writeFrame(Frame.tombstone(key));
      var deletedEntry = _keys.remove(key);
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
    var entriesToDelete = List<KeyEntry>();
    var tombstoneFrames = List<Frame>();
    var result = List<bool>(keysToDelete.length);
    var i = 0;
    for (var key in keysToDelete) {
      if (!_keys.containsKey(key)) {
        result[i++] = false;
      } else {
        entriesToDelete.add(_keys[key]);
        tombstoneFrames.add(Frame.tombstone(key));
        result[i++] = true;
      }
    }

    if (entriesToDelete.isEmpty) {
      return [];
    }

    var tombstoneEntries = await writeFrames(tombstoneFrames);

    for (var entry in entriesToDelete) {
      var deletedEntry = _keys.remove(entry.key);
      _deletedBytes += deletedEntry.length;
    }

    for (var tombstoneEntry in tombstoneEntries) {
      _totalBytes += tombstoneEntry.length;
      _deletedBytes += tombstoneEntry.length;
    }

    await performCompactationIfNeeded();

    for (var entry in entriesToDelete) {
      notifyChange(entry.key, null, true);
    }

    return result;
  }

  @visibleForTesting
  Future<KeyEntry> writeFrame(Frame frame) async {
    var bytes = frame.toBytes(
      this,
      encryptor: _cryptoHelper?.encryptor,
    );

    var offset = await _hiveFile.write(bytes); // Append to file
    return KeyEntry(frame.key, offset, bytes.length);
  }

  @visibleForTesting
  Future<List<KeyEntry>> writeFrames(List<Frame> frames) async {
    var bytes = BytesBuilder(copy: false);
    var frameLengths = List<int>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frameBytes = frames[i].toBytes(
        this,
        encryptor: _cryptoHelper?.encryptor,
      );
      bytes.add(frameBytes);
      frameLengths[i] = frameBytes.length;
    }

    var offset = await _hiveFile.write(bytes.toBytes()); // Append to file

    var keyEntries = List<KeyEntry>(frames.length);
    for (int i = 0; i < frames.length; i++) {
      var frame = frames[i];
      var frameLength = frameLengths[i];
      keyEntries[i] = KeyEntry(frame.key, offset, frameLength);
      offset += frameLength;
    }

    return keyEntries;
  }

  @override
  Future<Iterable<String>> allKeys() async {
    _checkOpen();
    return _keys.keys;
  }

  @override
  Future<Map<String, dynamic>> toMap() async {
    _checkOpen();
    var map = Map<String, dynamic>();

    await _hiveFile.syncWrite((file) async {
      var stream = Frame.streamAll(
        File(_hiveFile.path),
        this,
        readValue: true,
      );
      await for (var frame in stream) {
        if (frame.error == null) {
          map[frame.key] = frame.value;
        } else {
          throw frame.error;
        }
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
    _checkOpen();
    await _hiveFile.syncReadWrite((syncedHiveFile) async {
      var hiveFile = File(syncedHiveFile.path);

      var compactWriter = BinaryWriterImpl(this);
      var bufferedHiveFile = await BufferedFileReader.fromFile(hiveFile);
      var oldHeaderBytes = await bufferedHiveFile.read(Header.headerLength);
      await compactWriter.writeBytes(oldHeaderBytes);

      var compactFilePath = p.join(p.dirname(hiveFile.path), '$name.hivec');
      var compactFile = await File(compactFilePath).open(mode: FileMode.write);
      var compactOffset = Header.headerLength;

      var newKeys = LinkedHashMap<String, KeyEntry>();

      try {
        for (var entry in _keys.values) {
          if (entry.offset != bufferedHiveFile.offset) {
            await bufferedHiveFile.skip(entry.offset - bufferedHiveFile.offset);
          }
          var frameBytes = await bufferedHiveFile.read(entry.length);
          if (frameBytes.length != entry.length) {
            throw HiveError.corrupted(
                name, "Could not compact box: Unexpected EOF.");
          }
          compactWriter.writeBytes(frameBytes);

          if (compactWriter.writtenBytes > 1000) {
            await compactFile.writeFrom(compactWriter.outputAndClear());
          }
          newKeys[entry.key] = KeyEntry(entry.key, compactOffset, entry.length);
          compactOffset += entry.length;
        }
        await compactFile.writeFrom(compactWriter.outputAndClear());
      } finally {
        await bufferedHiveFile.close();
        await compactFile.close();
      }

      await syncedHiveFile.close();
      await File(compactFile.path).rename(hiveFile.path);
      _keys = newKeys;

      _totalBytes = compactOffset;
      _deletedBytes = 0;
    });

    await _hiveFile.open();
  }

  @override
  Future<int> clear() async {
    _checkOpen();

    var count = _keys.length;
    if (count == 0) return 0;

    for (var key in _keys.keys) {
      notifyChange(key, null, true);
    }

    await _hiveFile.truncate(Header.headerLength);
    _keys.clear();

    return count;
  }

  @override
  Future close({bool compact = false}) async {
    if (!_open) {
      return;
    }
    await _streamController.close();
    if (compact) {
      await this.compact();
    }
    _open = false;
    _keys = null;
    _hive.unregisterBox(name);
    await _hiveFile.close();
  }

  @override
  File getBoxFile() {
    return File(_hiveFile.path);
  }

  @override
  Future deleteFromDisk() async {
    _checkOpen();
    await _streamController.close();
    _open = false;
    _keys = null;
    _hive.unregisterBox(name);
    await _hiveFile.delete();
  }

  @visibleForTesting
  Map<String, KeyEntry> get keysForTest => _keys;

  @visibleForTesting
  int get deletedBytesForTest => _deletedBytes;

  @visibleForTesting
  int get totalBytesForTest => _totalBytes;
}
