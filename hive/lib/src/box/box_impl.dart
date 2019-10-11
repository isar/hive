import 'dart:async';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/list_view.dart';
import 'package:hive/src/box/map_view.dart';
import 'package:hive/src/hive_impl.dart';

class BoxImpl extends BoxBase {
  BoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
  ) : super(hive, name, keyComparator, compactionStrategy, backend);

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
    checkOpen();

    var frame = keystore.getAt(index);
    if (frame != null) {
      return frame.value;
    } else {
      return defaultValue;
    }
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) {
    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
    }

    return _writeFrames(frames);
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) {
    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    return _writeFrames(frames);
  }

  Future<void> _writeFrames(List<Frame> frames) async {
    checkOpen();

    if (!keystore.beginTransaction(frames)) return;

    try {
      await backend.writeFrames(frames);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
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
