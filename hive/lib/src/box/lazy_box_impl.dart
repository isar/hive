import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/lazy_transaction.dart';
import 'package:hive/src/box/transaction_base.dart';
import 'package:hive/src/hive_impl.dart';

class LazyBoxImpl extends BoxBase<LazyBox> implements LazyBox {
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
  Future put(dynamic key, dynamic value) async {
    checkOpen();

    var keyExists = keystore.containsKey(key);
    if (value == null && !keyExists) return;

    if (key is int) {
      updateAutoIncrement(key);
    }

    var entry = value != null ? BoxEntry(null) : null;
    await backend.writeFrame(Frame(key, value), entry);
    keystore.addAll({key: entry});
    if (keyExists) deletedEntries++;
    notifier.notify(key, value);

    await performCompactionIfNeeded();
  }

  @override
  Future putAll(Map<dynamic, dynamic> kvPairs) async {
    checkOpen();

    if (kvPairs.isEmpty) return;

    var toBeDeletedEntries = 0;
    var frames = <Frame>[];
    var entries = <dynamic, BoxEntry>{};
    kvPairs.forEach((key, dynamic value) {
      var keyExists = keystore.containsKey(key);
      if (value != null) {
        frames.add(Frame(key, value));
        entries[key] = BoxEntry(null);
        if (keyExists) {
          toBeDeletedEntries++;
        } else if (key is int) {
          updateAutoIncrement(key);
        }
      } else if (keyExists) {
        frames.add(Frame(key, null));
        entries[key] = null;
        toBeDeletedEntries++;
      }
    });

    if (frames.isEmpty) return;

    await backend.writeFrames(frames, entries.values);
    deletedEntries += toBeDeletedEntries;

    keystore.addAll(entries);

    for (var frame in frames) {
      notifier.notify(frame.key, frame.value);
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<Map<dynamic, dynamic>> toMap() {
    checkOpen();

    return backend.readAll();
  }

  @override
  TransactionBase<LazyBox> getTransaction() {
    return LazyTransaction(this, autoIncrement);
  }
}
