import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/hive_object.dart';
import 'package:hive/src/query/hive_query_impl.dart';

class BoxImpl extends BoxBase {
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

  Iterable<Frame> get frames => keystore.frames.values;

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) {
    checkOpen();
    var frame = keystore.get(key);
    if (frame != null) {
      return frame.value;
    } else {
      return defaultValue;
    }
  }

  @override
  dynamic getAt(int index, {dynamic defaultValue}) {
    var key = keystore.keyAt(index);
    if (key != null) {
      return get(key);
    } else {
      return defaultValue;
    }
  }

  @override
  HiveQuery<T> query<T extends HiveObject>() {
    return HiveQueryImpl<T>(this);
  }

  @override
  Future<void> put(dynamic key, dynamic value) {
    checkOpen();
    var frame = Frame(key, value);
    keystore.beginAddTransaction([frame]);
    initHiveObject(value, this, key);
    return _writeFrame(frame);
  }

  @override
  Future<void> delete(dynamic key) {
    checkOpen();
    if (!keystore.containsKey(key)) return Future.value();
    keystore.beginDeleteTransaction([key]);
    return _writeFrame(Frame.deleted(key));
  }

  Future<void> _writeFrame(Frame frame) async {
    notifier.notify(frame.key, frame.value, frame.deleted);
    try {
      await backend.writeFrame(frame);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      var oldFrame = keystore.get(frame.key);
      notifier.notify(frame.key, oldFrame?.value, oldFrame == null);
      rethrow;
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) {
    checkOpen();

    if (kvPairs.isEmpty) return Future.value();

    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      var value = kvPairs[key];
      initHiveObject(value, this, key);
      frames.add(Frame(key, value));
    }

    keystore.beginAddTransaction(frames);

    return _writeFrames(frames);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) {
    checkOpen();

    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    if (frames.isEmpty) return Future.value();

    keystore.beginDeleteTransaction(keys);
    return _writeFrames(frames);
  }

  Future<void> _writeFrames(List<Frame> frames) async {
    for (var frame in frames) {
      notifier.notify(frame.key, frame.value, frame.deleted);
    }

    try {
      await backend.writeFrames(frames);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      for (var frame in frames) {
        var oldFrame = keystore.get(frame.key);
        notifier.notify(frame.key, oldFrame?.value, oldFrame == null);
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
