import 'dart:async';
import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

export 'package:hive/src/backend/storage_backend_stub.dart'
    if (dart.library.io) 'package:hive/src/backend/storage_backend_vm.dart'
    if (dart.library.html) 'package:hive/src/backend/storage_backend_js.dart';

class BoxEntry {
  final dynamic value;
  final int offset;
  final int length;

  const BoxEntry(this.value, this.offset, this.length);

  @override
  bool operator ==(dynamic other) {
    if (other is BoxEntry) {
      return other.value == value &&
          other.offset == offset &&
          other.length == length;
    }
    return false;
  }
}

class BoxImpl extends BoxBase {
  static const deletedRatio = 0.15;
  static const deletedThreshold = 40;

  final HiveImpl hive;
  @override
  final String name;
  final BoxOptions options;
  final StorageBackend _backend;
  final _streamController = StreamController<BoxEvent>.broadcast();

  Map<String, BoxEntry> _entries = HashMap();

  bool _open = true;
  int _deletedEntries = 0;

  BoxImpl(this.hive, this.name, this.options, this._backend) : super(hive);

  BoxImpl.debug(
      this.hive, this.name, this.options, this._backend, this._entries)
      : super(hive);

  @override
  bool get isOpen => _open;

  @override
  String get path => _backend.path;

  @override
  Iterable<String> get keys {
    checkOpen();
    return _entries.keys;
  }

  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError('Box has already been closed.');
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

  void _notifyChange(String key, dynamic value) {
    _streamController.add(BoxEvent(key, value));
  }

  Future initialize() async {
    _deletedEntries = await _backend.initialize(_entries, options.lazy);
  }

  @override
  Future<T> get<T>(String key, {T defaultValue}) {
    checkOpen();

    if (!_entries.containsKey(key)) return Future.value(defaultValue);
    if (options.lazy) return Future.value(_entries[key]?.value as T);

    var entry = _entries[key];
    return _backend.readValue(key, entry.offset, entry.length) as Future<T>;
  }

  @override
  dynamic operator [](String key) {
    if (!options.lazy) {
      throw HiveError('Only lazy boxes can be accessed using [].');
    }

    return _entries[key]?.value;
  }

  @override
  bool has(String key) {
    checkOpen();
    return _entries.containsKey(key);
  }

  @override
  Future put(String key, dynamic value) async {
    checkOpen();

    var frame = Frame(key, value);
    if (value != null) {
      var entry = await _backend.writeFrame(frame, options.lazy);
      if (_entries.containsKey(key)) {
        _deletedEntries++;
      }
      _entries[key] = entry;
    } else {
      if (!_entries.containsKey(key)) return;
      await _backend.writeFrame(frame, options.lazy);
      _deletedEntries++;
      _entries.remove(key);
    }

    await performCompactationIfNeeded();

    _notifyChange(key, value);
  }

  @override
  Future delete(String key) {
    return put(key, null);
  }

  @override
  Future putAll(Map<String, dynamic> kvPairs) async {
    checkOpen();
    if (kvPairs.isEmpty) return;

    var toBeDeletedEntries = 0;
    var frames = <Frame>[];
    kvPairs.forEach((key, dynamic val) {
      var frame = Frame(key, val);
      if (val != null) {
        frames.add(frame);
        if (_entries.containsKey(key)) {
          toBeDeletedEntries++;
        }
      } else {
        if (_entries.containsKey(key)) {
          frames.add(frame);
          toBeDeletedEntries++;
        }
      }
    });

    var newEntries = await _backend.writeFrames(frames, options.lazy);
    for (var i = 0; i < frames.length; i++) {
      var frame = frames[i];
      if (frame.value != null) {
        _entries[frame.key] = newEntries[i];
      } else {
        _entries.remove(frame.key);
      }
    }

    _deletedEntries += toBeDeletedEntries;

    await performCompactationIfNeeded();

    if (_streamController.hasListener) {
      kvPairs.forEach(_notifyChange);
    }
  }

  @override
  Future deleteAll(Iterable<String> keysToDelete) {
    var nullValues = List.filled(keysToDelete.length, null);
    return putAll(Map<String, void>.fromIterables(keysToDelete, nullValues));
  }

  @override
  Future<Map<String, dynamic>> toMap() {
    checkOpen();

    if (options.lazy) {
      var mappedEntries =
          _entries.map<String, dynamic>((k, e) => MapEntry(k, e.value));
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
      _notifyChange(key, null);
    }

    return oldEntries.length;
  }

  @override
  Future<void> compact() async {
    checkOpen();
    if (_deletedEntries == 0) return;
    var newEntries = await _backend.compact(_entries);
    if (newEntries != null) {
      _entries = newEntries;
      _deletedEntries = 0;
    }
  }

  @visibleForTesting
  Future<void> performCompactationIfNeeded() {
    if (_deletedEntries > deletedThreshold) {
      if (_deletedEntries / _entries.length > deletedRatio) {
        return compact();
      }
    }

    return Future.value();
  }

  @override
  Future<void> close() async {
    if (!_open) return;

    await waitForRunningTransactions();
    await _streamController.close();

    _open = false;
    hive.unregisterBox(name);
    await _backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    await _streamController.close();
    await waitForRunningTransactions();
    _open = false;
    hive.unregisterBox(name);
    await _backend.deleteFromDisk();
  }

  @visibleForTesting
  Map<String, BoxEntry> get debugEntries => _entries;

  @visibleForTesting
  int get debugDeletedEntries => _deletedEntries;
}
