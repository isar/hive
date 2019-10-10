import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/list_view.dart';
import 'package:hive/src/box/map_view.dart';
import 'package:hive/src/hive_impl.dart';

class BoxImpl extends BoxBase {
  BoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend, [
    ChangeNotifier notifier,
  ]) : super(hive, name, keyComparator, compactionStrategy, backend, notifier);

  BoxImpl.debug({
    HiveImpl hive,
    String name,
    Keystore keystore,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
    ChangeNotifier notifier,
  }) : super.debug(hive, name, keystore, compactionStrategy, backend, notifier);

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

    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
    }

    return _writeFrames(frames);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) {
    checkOpen();

    var frames = <Frame>[];
    for (var key in keys) {
      frames.add(Frame.deleted(key));
    }

    return _writeFrames(frames);
  }

  Future<void> _writeFrames(List<Frame> frames) async {
    if (!keystore.beginTransaction(frames)) return;
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
  List<E> listView<E>() => ListView<E>(this);

  @override
  Map<dynamic, E> mapView<E>() => MapView<E>(this);

  @override
  Map<dynamic, dynamic> toMap() {
    return Map.from(mapView());
  }
}
