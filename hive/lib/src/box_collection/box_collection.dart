import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/hive_impl.dart';

import 'box_collection_stub.dart' as implementation;

class BoxCollection implements implementation.BoxCollection {
  @override
  final String name;

  @override
  Set<String> get boxNames => Set.from(_backends.keys);

  final Map<String, StorageBackend> _backends;

  HiveCipher? _cipher;

  BoxCollection(this.name, this._backends);

  static bool _hiveInit = false;

  late CollectionBox<String?> _badKeyBox;

  static Future<BoxCollection> open(
    String name,
    Set<String> boxNames, {
    String? path,
    @Deprecated('Use [cipher] instead') HiveCipher? key,
    HiveCipher? cipher,
  }) async {
    // compatibility for [key]
    cipher ??= key;

    if (!_hiveInit) {
      Hive.init(path ?? './');
      _hiveInit = true;
    }
    final names = boxNames..add('bad_keys');
    final backends = await (Hive as HiveImpl)
        .manager
        .openCollection(names, path, false, cipher, name);

    final collection = BoxCollection(name, backends);
    if (cipher != null) {
      collection._cipher = cipher;
    }

    collection._badKeyBox = await collection.openBox<String>('bad_keys');

    return collection;
  }

  @override
  Future<CollectionBox<V>> openBox<V>(String name,
      {bool preload = false,
      implementation.CollectionBox<V> Function(String, BoxCollection)?
          boxCreator}) async {
    if (!boxNames.contains(name) && name != 'bad_keys') {
      throw Exception('Box with name $name is not in the known'
          'box names of this collection.');
    }
    final i = _openBoxes.indexWhere((box) => box.name == name);
    if (i != -1) {
      return _openBoxes[i] as CollectionBox<V>;
    }
    final boxIdentifier = name;
    final box = boxCreator?.call(boxIdentifier, this) as CollectionBox<V>? ??
        CollectionBox<V>(boxIdentifier, this);
    if (preload) {
      final hive = Hive as HiveImpl;
      box._cachedBox = hive.isBoxOpen(box.name, this.name)
          ? hive.lazyBox(box.name, this.name)
          : await hive.openBox(
              box.name,
              encryptionCipher: _cipher,
              collection: this.name,
              backend: _backends[name]!,
            );
    }
    _openBoxes.add(box);
    return box;
  }

  final List<CollectionBox> _openBoxes = [];

  @override
  Future<void> transaction(
    Future<void> Function() action, {
    List<String>? boxNames,
    bool readOnly = false,
  }) async {
    await runZoned(() async {
      try {
        CollectionBox.transactionBoxes[Zone.current] = <String>{};
        await action();
      } finally {
        final flushFutures = <Future<void>>[];
        for (final boxName in CollectionBox.transactionBoxes[Zone.current]!) {
          final i = _openBoxes.indexWhere((box) => box.name == boxName);
          if (i != -1) {
            flushFutures.add(_openBoxes[i].flush());
          }
        }
        await Future.wait(flushFutures);
        CollectionBox.transactionBoxes.remove(Zone.current);
      }
    });
  }

  @override
  void close() {
    for (final box in _openBoxes) {
      box._cachedBox?.close();
    }
  }

  @override
  Future<void> deleteFromDisk() => Future.wait(
        boxNames.map((box) => Hive.deleteBoxFromDisk(box, collection: name)),
      );
}

/// represents a [Box] being part of a [BoxCollection]
class CollectionBox<V> implements implementation.CollectionBox<V> {
  @override
  final String name;
  @override
  final BoxCollection boxCollection;

  static final transactionBoxes = <Zone, Set<String>>{};

  BoxBase? _cachedBox;

  Future<BoxBase> _getBox() async {
    if (_cachedBox == null || !_cachedBox!.isOpen) {
      final hive = Hive as HiveImpl;
      _cachedBox = hive.isBoxOpen(name, boxCollection.name)
          ?  hive.lazyBox(name, boxCollection.name)
          : await hive.openLazyBox(
              name,
              encryptionCipher: boxCollection._cipher,
              collection: boxCollection.name,
              backend: boxCollection._backends[name]!,
            );
    }

    return _cachedBox!;
  }

  CollectionBox(this.name, this.boxCollection);

  @override
  Future<List<String>> getAllKeys() async {
    final box = await _getBox();

    return (await Future.wait(
      box.keys.whereType<String>().map(
        (key) async {
          if (key.startsWith(_badKeyPrefix)) {
            key = await boxCollection._badKeyBox.get(key) ?? key;
          }
          return key;
        },
      ),
    ))
        .map(Uri.decodeComponent)
        .toList();
  }

  @override
  Future<Map<String, V>> getAllValues() async {
    final box = await _getBox();
    final keys = box.keys.toList();
    if (box is LazyBox) {
      final values = await Future.wait(keys.map(box.get));
      return {
        for (var i = 0; i < values.length; i++)
          Uri.decodeComponent(keys[i] as String): values[i] as V
      };
    }
    return (box as Box)
        .toMap()
        .map((k, v) => MapEntry(Uri.decodeComponent(k.toString()), v as V));
  }

  @override
  Future<V?> get(String key) async {
    key = _toHiveKey(key);
    final box = await _getBox();
    if (box is LazyBox) return await box.get(key) as V?;
    return (box as Box).get(key) as V?;
  }

  @override
  Future<List<V?>> getAll(
    List<String> keys,
  ) async {
    final box = await _getBox();
    final values = <V?>[];
    for (var key in keys) {
      key = _toHiveKey(key);
      if (box is LazyBox) {
        values.add(await box.get(key) as V?);
      } else {
        values.add((box as Box).get(key) as V?);
      }
    }
    return values;
  }

  @override
  Future<void> put(String key, V val, [Object? transaction]) async {
    if (val == null) {
      return delete(key);
    }
    final box = await _getBox();
    await box.put(_toHiveKey(key), val);
    await _flushOrMark();
  }

  @override
  Future<void> delete(String key) async {
    final box = await _getBox();
    await box.delete(_toHiveKey(key));
    await _flushOrMark();
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    final hiveKeys = keys.map(_toHiveKey);
    final box = await _getBox();
    await box.deleteAll(hiveKeys);
    await _flushOrMark();
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.deleteAll(box.keys);
    await _flushOrMark();
  }

  @override
  Future<void> flush() async {
    // we do *not* await the flushing here. That makes it so that we can execute
    // other stuff while the flushing is still in progress. Fortunately, hive
    // has a proper read / write queue, meaning that if we do actually want to
    // write something again, it'll wait until the flush is completed.
    _getBox().then((box) => box.flush());
  }

  Future<void> _flushOrMark() async {
    final zone = _getTransactionZone();
    if (zone == null) {
      await flush();
    } else {
      transactionBoxes[zone]!.add(name);
    }
  }

  Zone? _getTransactionZone([Zone? testZone]) {
    testZone ??= Zone.current;
    if (testZone == Zone.root) {
      return null;
    }
    if (transactionBoxes.keys.contains(testZone)) {
      return testZone;
    }
    return _getTransactionZone(testZone.parent);
  }

  static const int _maxKeyLength = 255;
  static const String _badKeyPrefix = '_bad_key_';

  String _calcHashKey(String encodedKey) =>
      _badKeyPrefix + sha256.convert(utf8.encode(encodedKey)).toString();

  String _toHiveKey(String key) {
    final encodedKey = key.split('|').map(Uri.encodeComponent).join('|');
    if (encodedKey.length >= _maxKeyLength) {
      final hashKey = _calcHashKey(encodedKey);
      boxCollection._badKeyBox.put(hashKey, encodedKey);
      return hashKey;
    }
    return encodedKey;
  }
}
