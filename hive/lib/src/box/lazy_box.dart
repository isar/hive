import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:meta/meta.dart';

class LazyBox extends BoxBase {
  LazyBox(
    HiveImpl hive,
    String name,
    BoxOptions options,
    StorageBackend backend,
  ) : super(hive, name, options, backend);

  @visibleForTesting
  LazyBox.debug(
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

    var entry = keystore.get(key);

    if (entry != null) {
      return backend.readValue(key, entry.offset, entry.length);
    } else {
      return Future.value(defaultValue);
    }
  }

  @override
  dynamic operator [](String key) {
    throw HiveError('Lazy boxes cannot be accessed using [].');
  }

  @override
  Future put(String key, dynamic value) async {
    checkOpen();

    var keyExists = keystore.containsKey(key);
    if (value == null && !keyExists) return;

    var frame = Frame(key, value);
    var entry = BoxEntry(null);

    keystore.entries[key] = entry;

    await backend.writeFrame(frame, entry);
    if (keyExists) {
      deletedEntries++;
    }
    notifier.notify(key, value);

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
      entries[key] = BoxEntry(null);

      var keyExists = keystore.containsKey(key);
      if (keyExists) toBeDeletedEntries++;
    });

    await backend.writeFrames(frames, entries.values);
    deletedEntries += toBeDeletedEntries;

    keystore.entries.addAll(entries);

    for (var frame in frames) {
      notifier.notify(frame.key, frame.value);
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<Map<String, dynamic>> toMap() {
    checkOpen();

    return backend.readAll(keystore.getAll().keys);
  }
}
