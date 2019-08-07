import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/cached_transaction.dart';
import 'package:hive/src/box/transaction_base.dart';
import 'package:hive/src/hive_impl.dart';

class CachedBoxImpl extends BoxBase<CachedBox> implements CachedBox {
  CachedBoxImpl(
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
  Iterable get values {
    checkOpen();
    return keystore.getValues().map((it) => it.value);
  }

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    checkOpen();
    return Future.value(keystore.get(key)?.value ?? defaultValue);
  }

  @override
  dynamic operator [](dynamic key) {
    checkOpen();
    return keystore.get(key)?.value;
  }

  @override
  Future put(dynamic key, dynamic value) async {
    checkOpen();

    var keyExists = keystore.containsKey(key);
    if (value == null && !keyExists) return;

    if (key is int) {
      updateAutoIncrement(key);
    }

    var entry = value != null ? BoxEntry(value) : null;
    keystore.keyTransaction({key: entry});
    notifier.notify(key, value);

    try {
      await backend.writeFrame(Frame(key, value), entry);
      if (keyExists) deletedEntries++;
      keystore.commitKeyTransaction();
    } catch (e) {
      keystore.cancelKeyTransaction();
      notifier.notify(key, keystore.get(key)?.value);
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  void operator []=(dynamic key, dynamic value) {
    put(key, value);
  }

  @override
  Future putAll(Map<dynamic, dynamic> kvPairs) async {
    checkOpen();

    var toBeDeletedEntries = 0;
    var frames = <Frame>[];
    var entries = <dynamic, BoxEntry>{};
    kvPairs.forEach((key, dynamic value) {
      var keyExists = keystore.containsKey(key);
      if (value != null) {
        frames.add(Frame(key, value));
        entries[key] = BoxEntry(value);
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

    keystore.keyTransaction(entries);
    for (var frame in frames) {
      notifier.notify(frame.key, frame.value);
    }

    try {
      await backend.writeFrames(frames, entries.values);
      deletedEntries += toBeDeletedEntries;
      keystore.commitKeyTransaction();
    } catch (e) {
      keystore.cancelKeyTransaction();
      for (var frame in frames) {
        notifier.notify(frame.key, keystore.get(frame.key)?.value);
      }
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, dynamic> toMap() {
    checkOpen();
    return keystore.toMap();
  }

  @override
  TransactionBase<CachedBox> getTransaction() {
    return CachedTransaction(this, autoIncrement);
  }
}
