import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';

class LazyBoxImpl extends BoxBase implements LazyBox {
  LazyBoxImpl(
    HiveImpl hive,
    String name,
    BoxOptions options,
    StorageBackend backend, [
    Keystore keystore,
    ChangeNotifier notifier,
  ]) : super(hive, name, options, backend, keystore, notifier);

  @override
  final bool lazy = true;

  @override
  Iterable get values =>
      throw UnsupportedError('Only non-lazy boxes have this property.');

  @override
  Future<dynamic> get(dynamic key, {dynamic defaultValue}) {
    checkOpen();

    var entry = keystore.get(key);

    if (entry != null) {
      return backend.readValue(key, entry.offset, entry.length);
    } else {
      return Future.value(defaultValue);
    }
  }

  @override
  Future<dynamic> getAt(int index) {
    return get(keystore.keyAt(index));
  }

  @override
  Future<void> put(dynamic key, dynamic value) async {
    checkOpen();

    if (key is int) {
      keystore.updateAutoIncrement(key);
    }

    var entry = BoxEntry(null);
    await backend.writeFrame(Frame(key, value), entry);
    keystore.addAll({key: entry});
    notifier.notify(key, value, false);

    await performCompactionIfNeeded();
  }

  @override
  Future<void> delete(dynamic key) async {
    checkOpen();

    if (!keystore.containsKey(key)) return;

    await backend.writeFrame(Frame.deleted(key), null);
    keystore.deleteAll([key]);
    notifier.notify(key, null, true);

    await performCompactionIfNeeded();
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) async {
    checkOpen();

    var frames = <Frame>[];
    var entries = <dynamic, BoxEntry>{};
    for (var key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
      entries[key] = BoxEntry(null);
      if (key is int) {
        keystore.updateAutoIncrement(key);
      }
    }

    await backend.writeFrames(frames, entries.values);

    keystore.addAll(entries);

    for (var frame in frames) {
      notifier.notify(frame.key, frame.value, false);
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> deleteAll(List<dynamic> keys) async {
    checkOpen();

    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    if (frames.isEmpty) return;

    await backend.writeFrames(frames, null);

    keystore.deleteAll(keys);

    for (var frame in frames) {
      notifier.notify(frame.key, frame.value, true);
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, dynamic> toMap() {
    throw UnsupportedError('Only non-lazy boxes support toMap().');
  }
}
