import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';

class BoxImpl extends BoxBase implements Box {
  BoxImpl(
    HiveImpl hive,
    String name,
    BoxOptions options,
    StorageBackend backend, [
    Keystore keystore,
    ChangeNotifier notifier,
  ]) : super(hive, name, options, backend, keystore, notifier);

  @override
  final bool lazy = false;

  @override
  Iterable<dynamic> get values {
    checkOpen();
    return keystore.getValues();
  }

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    checkOpen();
    var entry = keystore.get(key);
    if (entry != null) {
      return entry.value;
    } else {
      return defaultValue;
    }
  }

  @override
  dynamic getAt(int index) {
    return get(keystore.keyAt(index));
  }

  @override
  Future<void> put(dynamic key, dynamic value) {
    checkOpen();
    var entry = BoxEntry(value);
    keystore.beginAddTransaction({key: entry});
    return _writeFrame(Frame(key, value), entry);
  }

  @override
  Future<void> delete(dynamic key) {
    checkOpen();
    if (!keystore.containsKey(key)) return Future.value();
    keystore.beginDeleteTransaction([key]);
    return _writeFrame(Frame.deleted(key), null);
  }

  Future<void> _writeFrame(Frame frame, BoxEntry entry) async {
    notifier.notify(frame.key, frame.value, frame.deleted);
    try {
      await backend.writeFrame(frame, entry);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      var oldEntry = keystore.get(frame.key);
      notifier.notify(frame.key, oldEntry?.value, oldEntry == null);
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) {
    checkOpen();

    if (kvPairs.isEmpty) return Future.value();

    var frames = <Frame>[];
    var entries = <dynamic, BoxEntry>{};
    for (var key in kvPairs.keys) {
      var value = kvPairs[key];
      frames.add(Frame(key, value));
      entries[key] = BoxEntry(value);
    }

    keystore.beginAddTransaction(entries);

    return _writeFrames(frames, entries.values);
  }

  @override
  Future<void> deleteAll(List<dynamic> keys) {
    checkOpen();

    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    if (frames.isEmpty) return Future.value();

    keystore.beginDeleteTransaction(keys);
    return _writeFrames(frames, null);
  }

  Future<void> _writeFrames(
      List<Frame> frames, Iterable<BoxEntry> entries) async {
    for (var frame in frames) {
      notifier.notify(frame.key, frame.value, frame.deleted);
    }

    try {
      await backend.writeFrames(frames, entries);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      for (var frame in frames) {
        var oldEntry = keystore.get(frame.key);
        notifier.notify(frame.key, oldEntry?.value, oldEntry == null);
      }
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, dynamic> toMap() {
    checkOpen();
    return keystore.toValueMap();
  }
}
