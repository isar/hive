import 'dart:async';
import 'dart:collection';

import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';

class CachedBox extends BoxBase {
  CachedBox(
    HiveImpl hive,
    String name,
    BoxOptions options,
    StorageBackend backend, [
    Keystore keystore,
    ChangeNotifier notifier,
  ]) : super(hive, name, options, backend, keystore, notifier);

  @override
  Future<dynamic> get(String key, {dynamic defaultValue}) {
    checkOpen();
    return Future.value(keystore.get(key)?.value ?? defaultValue);
  }

  @override
  dynamic operator [](String key) {
    checkOpen();
    return keystore.get(key)?.value;
  }

  @override
  Future put(String key, dynamic value) async {
    checkOpen();

    var keyExists = keystore.containsKey(key);
    if (value == null && !keyExists) return;

    var entry = value != null ? BoxEntry(value) : null;
    var keyTrx = keystore.keyTransaction({key: entry});
    notifier.notify(key, value);

    try {
      await backend.writeFrame(Frame(key, value), entry);
      if (keyExists) deletedEntries++;
      keyTrx.commit();
    } catch (e) {
      keyTrx.cancel();
      notifier.notify(key, keystore.get(key)?.value);
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  void operator []=(String key, dynamic value) {
    put(key, value);
  }

  @override
  Future putAll(Map<String, dynamic> kvPairs) async {
    checkOpen();

    var toBeDeletedEntries = 0;
    var frames = <Frame>[];
    var entries = <String, BoxEntry>{};
    kvPairs.forEach((key, dynamic value) {
      var keyExists = keystore.containsKey(key);
      if (value != null) {
        frames.add(Frame(key, value));
        entries[key] = BoxEntry(value);
        if (keyExists) toBeDeletedEntries++;
      } else if (keyExists) {
        frames.add(Frame(key, null));
        entries[key] = null;
        toBeDeletedEntries++;
      }
    });

    if (frames.isEmpty) return;

    var transaction = keystore.keyTransaction(entries);
    for (var frame in frames) {
      notifier.notify(frame.key, frame.value);
    }

    try {
      await backend.writeFrames(frames, entries.values);
      deletedEntries += toBeDeletedEntries;
      transaction.commit();
    } catch (e) {
      transaction.cancel();
      for (var frame in frames) {
        notifier.notify(frame.key, keystore.get(frame.key)?.value);
      }
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<Map<String, dynamic>> toMap() {
    checkOpen();
    var mappedEntries = HashMap<String, dynamic>();
    var entries = keystore.getAll();
    for (var key in entries.keys) {
      mappedEntries[key] = entries[key].value;
    }

    return Future.value(mappedEntries);
  }
}
