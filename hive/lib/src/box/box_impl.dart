import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/storage_backend.dart';
import 'package:hive/src/frame.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

export 'package:hive/src/box/storage_backend_stub.dart'
    if (dart.library.io) 'package:hive/src/box/storage_backend_vm.dart'
    if (dart.library.html) 'package:hive/src/box/storage_backend_js.dart';

class BoxEntry {
  final dynamic value;
  final int offset;
  final int length;

  const BoxEntry(this.value, this.offset, this.length);
}

class BoxImpl extends TypeRegistryImpl implements Box {
  static const deletedRatio = 0.15;
  static const deletedThreshold = 40;

  final HiveImpl hive;
  final String name;
  final BoxOptions options;
  final StorageBackend _backend;
  final _streamController = StreamController<BoxEvent>.broadcast();

  Map<String, BoxEntry> _entries = HashMap();

  bool _open = true;
  int _deletedEntries = 0;

  BoxImpl(this.hive, this.name, this.options, this._backend) : super(hive);

  @override
  bool get isOpen => _open;

  @override
  String get path => _backend.path;

  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError("Box has already been closed.");
    }
  }

  @override
  Stream<BoxEvent> watch({String key}) {
    checkOpen();
    if (key != null) {
      return _streamController.stream.where((it) => it.key == key);
    } else {
      return _streamController.stream;
    }
  }

  void _notifyChange(String key, dynamic value, bool deleted) {
    _streamController.add(BoxEvent(key, value, deleted));
  }

  Future initialize() async {
    _deletedEntries = await _backend.initialize(_entries, options.cacheAll);
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) {
    checkOpen();

    if (!_entries.containsKey(key)) return Future.value(defaultValue);
    if (options.cacheAll) return Future.value(_entries[key]?.value);

    return _backend.readValue(key, _entries[key].offset);
  }

  @override
  Future operator [](String key) => get(key);

  @override
  bool has(String key) {
    checkOpen();
    return _entries.containsKey(key);
  }

  @override
  Future put(String key, dynamic value) async {
    checkOpen();

    var entry = await _backend.writeFrame(Frame(key, value), options.cacheAll);

    if (_entries.containsKey(key)) {
      _deletedEntries++;
    }

    _entries[key] = entry;

    await performCompactationIfNeeded();

    _notifyChange(key, value, false);
  }

  @override
  Future putAll(Map<String, dynamic> kvPairs) async {
    checkOpen();
    if (kvPairs.isEmpty) {
      return;
    }
    var frames = List<Frame>();
    kvPairs.forEach((key, val) {
      frames.add(Frame(key, val));
    });

    var newEntries = await _backend.writeFrames(frames, options.cacheAll);
    for (int i = 0; i < frames.length; i++) {
      var frame = frames[i];
      if (_entries.containsKey(frame.key)) {
        _deletedEntries++;
      }

      _entries[frame.key] = newEntries[i];
    }

    await performCompactationIfNeeded();

    if (_streamController.hasListener) {
      kvPairs.forEach((k, v) {
        _notifyChange(k, v, false);
      });
    }
  }

  @override
  Future<bool> delete(String key) async {
    checkOpen();
    if (_entries.containsKey(key)) {
      await _backend.writeFrame(Frame.tombstone(key), options.cacheAll);
      _entries.remove(key);
      _deletedEntries++;
      await performCompactationIfNeeded();

      _notifyChange(key, null, true);
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<List<bool>> deleteAll(Iterable<String> keysToDelete) async {
    checkOpen();
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

    await _backend.writeFrames(tombstoneFrames, options.cacheAll);

    for (var frame in tombstoneFrames) {
      _entries.remove(frame.key);
    }
    _deletedEntries += tombstoneFrames.length;

    await performCompactationIfNeeded();

    if (_streamController.hasListener) {
      for (var frame in tombstoneFrames) {
        _notifyChange(frame.key, null, true);
      }
    }

    return result;
  }

  @override
  Iterable<String> allKeys() {
    checkOpen();
    return _entries.keys;
  }

  @override
  Future<Map<String, dynamic>> toMap() {
    checkOpen();

    if (options.cacheAll) {
      var mappedEntries = _entries.map((k, e) => MapEntry(k, e.value));
      return Future.value(mappedEntries);
    }

    return _backend.readAll(_entries.keys);
  }

  @override
  Future<int> clear() async {
    checkOpen();
    if (_entries.isEmpty) return 0;

    await _backend.clear();
    var oldEntries = _entries;
    _entries = HashMap();
    _deletedEntries = 0;

    for (var key in oldEntries.keys) {
      _notifyChange(key, null, true);
    }

    return oldEntries.length;
  }

  @override
  Future<void> compact() async {
    checkOpen();
    var newEntries = await _backend.compact(_entries);
    if (newEntries != null) {
      _entries = newEntries;
      _deletedEntries = 0;
    }
  }

  @visibleForTesting
  Future performCompactationIfNeeded() {
    if (_deletedEntries > deletedThreshold) {
      if (_deletedEntries / _entries.length > deletedRatio) {
        return compact();
      }
    }

    return Future.value();
  }

  @override
  Future<void> close({bool compact = false}) async {
    if (!_open) return;
    if (compact) {
      await _backend.compact(_entries);
    }

    await _streamController.close();
    _open = false;
    hive.unregisterBox(name);
    await _backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    await _streamController.close();
    _open = false;
    hive.unregisterBox(name);
    await _backend.deleteFromDisk();
  }

  int getKeyOffset(String key) {
    return _entries[key].offset;
  }
}
