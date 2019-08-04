import 'dart:async';

import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

class CachedBox extends BoxBase {
  CachedBox(
    HiveImpl hive,
    String name,
    BoxOptions options,
    StorageBackend backend,
  ) : super(hive, name, options, backend);

  @visibleForTesting
  CachedBox.debug(
    HiveImpl hive,
    String name,
    BoxOptions options,
    StorageBackend backend,
    Keystore keystore, [
    ChangeNotifier notifier,
  ]) : super.debug(hive, name, options, backend, keystore, notifier);

  @override
  Future<dynamic> get(String key, {dynamic defaultValue}) {
    checkOpen();

    return Future.value(keystore.get(key)?.value ?? defaultValue);
  }

  @override
  dynamic operator [](String key) {
    return keystore.get(key)?.value;
  }

  @override
  Future put(String key, dynamic value) async {
    checkOpen();

    var keyExists = keystore.containsKey(key);
    if (value == null && !keyExists) return;

    var frame = Frame(key, value);
    var entry = BoxEntry(value);

    var transaction = keystore.keyTransaction({key: entry});
    notifier.notify(key, value);

    try {
      await backend.writeFrame(frame, entry);
      if (keyExists) deletedEntries++;
      transaction?.commit();
    } catch (e) {
      transaction?.cancel();
      notifier.notify(key, value);
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Future putAll(Map<String, dynamic> kvPairs) async {
    checkOpen();
    if (kvPairs.isEmpty) return;

    var toBeDeletedEntries = 0;
    var frames = <Frame>[];
    var entries = <String, BoxEntry>{};
    kvPairs.forEach((key, dynamic value) {
      frames.add(Frame(key, value));
      entries[key] = BoxEntry(value);

      var keyExists = keystore.containsKey(key);
      if (keyExists) toBeDeletedEntries++;
    });

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
      for (var key in entries.keys) {
        notifier.notify(key, keystore.get(key));
      }
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<Map<String, dynamic>> toMap() {
    checkOpen();

    var mappedEntries = <String, Frame>{};
    keystore.getAll().map((key, entry) => MapEntry(key, entry.value));

    return Future.value(mappedEntries);
  }
}
