import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/hive_impl.dart';

class LazyBoxImpl extends BoxBase implements LazyBox {
  LazyBoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
  ) : super(hive, name, keyComparator, compactionStrategy, backend);

  @override
  final bool lazy = true;

  @override
  Iterable get values =>
      throw UnsupportedError('Only non-lazy boxes have this property.');

  @override
  Future<dynamic> get(dynamic key, {dynamic defaultValue}) async {
    checkOpen();

    var frame = keystore.get(key);

    if (frame != null) {
      var value = await backend.readValue(frame);
      return value;
    } else {
      return defaultValue;
    }
  }

  @override
  Future<dynamic> getAt(int index, {dynamic defaultValue}) {
    var frame = keystore.getAt(index);
    if (frame != null) {
      return get(frame.key);
    } else {
      return Future.value(defaultValue);
    }
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) async {
    checkOpen();

    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
      if (key is int) {
        keystore.updateAutoIncrement(key);
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames);

    for (var frame in frames) {
      keystore.insert(Frame.lazy(
        frame.key,
        length: frame.length,
        offset: frame.offset,
      ));
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    checkOpen();

    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames);

    for (var frame in frames) {
      keystore.insert(frame);
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, dynamic> toMap() {
    throw UnsupportedError('Only non-lazy boxes support toMap().');
  }
}
