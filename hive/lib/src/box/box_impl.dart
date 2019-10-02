import 'dart:async';

import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';

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
    var frame = keystore.getAt(index);
    if (frame != null) {
      return frame.value;
    } else {
      return defaultValue;
    }
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) {
    checkOpen();

    if (kvPairs.isEmpty) return Future.value();

    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      var value = kvPairs[key];
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
    notifier.notify(frames);

    try {
      await backend.writeFrames(frames);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      var notifyFrames = <Frame>[];
      for (var frame in frames) {
        var oldFrame = keystore.get(frame.key);
        if (oldFrame == null) {
          notifyFrames.add(Frame.deleted(frame.key));
        } else {
          notifyFrames.add(Frame(frame.key, oldFrame.value));
        }
        notifier.notify(notifyFrames);
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
