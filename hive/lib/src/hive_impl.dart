import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:hive/src/util/extensions.dart';
import 'package:meta/meta.dart';

import 'backend/storage_backend.dart';

/// Not part of public API
class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  static final BackendManagerInterface _defaultBackendManager =
      BackendManager.select();

  final _boxes = HashMap<TupleBoxKey, BoxBaseImpl>();
  final _openingBoxes = HashMap<TupleBoxKey, Future>();
  BackendManagerInterface? _managerOverride;
  final Random _secureRandom = Random.secure();

  /// Not part of public API
  @visibleForTesting
  String? homePath;

  /// Not part of public API
  HiveImpl() {
    _registerDefaultAdapters();
  }

  /// either returns the preferred [BackendManagerInterface] or the
  /// platform default fallback
  BackendManagerInterface get manager =>
      _managerOverride ?? _defaultBackendManager;

  void _registerDefaultAdapters() {
    registerAdapter(DateTimeWithTimezoneAdapter(), internal: true);
    registerAdapter(DateTimeAdapter<DateTimeWithoutTZ>(), internal: true);
    registerAdapter(BigIntAdapter(), internal: true);
  }

  @override
  void init(
    String? path, {
    HiveStorageBackendPreference backendPreference =
        HiveStorageBackendPreference.native,
  }) {
    homePath = path;
    _managerOverride = BackendManager.select(backendPreference);
  }

  Future<BoxBase<E>> _openBox<E>(
    String name,
    bool lazy,
    HiveCipher? cipher,
    KeyComparator comparator,
    CompactionStrategy compaction,
    bool recovery,
    String? path,
    StorageBackend? backend,
    String? collection,
  ) async {
    assert(path == null || backend == null);
    assert(name.length <= 255 && name.isAscii,
        'Box names need to be ASCII Strings with a max length of 255.');
    name = name.toLowerCase();
    if (isBoxOpen(name)) {
      if (lazy) {
        return lazyBox(name);
      } else {
        return box(name);
      }
    } else {
      if (_openingBoxes.containsKey(TupleBoxKey(name, collection))) {
        await _openingBoxes[TupleBoxKey(name, collection)];
        if (lazy) {
          return lazyBox(name);
        } else {
          return box(name);
        }
      }

      var completer = Completer();
      _openingBoxes[TupleBoxKey(name, collection)] = completer.future;

      BoxBaseImpl<E>? newBox;
      try {
        backend ??= await manager.open(
            name, path ?? homePath, recovery, cipher, collection);

        if (lazy) {
          newBox = LazyBoxImpl<E>(this, name, comparator, compaction, backend);
        } else {
          newBox = BoxImpl<E>(this, name, comparator, compaction, backend);
        }

        await newBox.initialize();
        _boxes[TupleBoxKey(name, collection)] = newBox;

        completer.complete();
        return newBox;
      } catch (error, stackTrace) {
        newBox?.close();
        completer.completeError(error, stackTrace);
        rethrow;
      } finally {
        // ignore: unawaited_futures
        _openingBoxes.remove(TupleBoxKey(name, collection));
      }
    }
  }

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    @Deprecated('Use [backend] with a [StorageBackendMemory] instead')
        Uint8List? bytes,
    StorageBackend? backend,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  }) async {
    if (encryptionKey != null) {
      encryptionCipher = HiveAesCipher(encryptionKey);
    }
    if (backend == null && bytes != null) {
      backend = StorageBackendMemory(bytes, encryptionCipher);
    }
    return await _openBox<E>(name, false, encryptionCipher, keyComparator,
        compactionStrategy, crashRecovery, path, backend, collection) as Box<E>;
  }

  @override
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
    StorageBackend? backend,
  }) async {
    if (encryptionKey != null) {
      encryptionCipher = HiveAesCipher(encryptionKey);
    }
    return await _openBox<E>(
        name,
        true,
        encryptionCipher,
        keyComparator,
        compactionStrategy,
        crashRecovery,
        path,
        backend,
        collection) as LazyBox<E>;
  }

  /*Future<Map<String, LazyBox>> openBoxCollection(
      String name, Set<String> boxNames, HiveCipher? cipher, String? path) async
      {
    final backends =
        await manager.openCollection(boxNames, path, false, cipher, name);
    return Map.fromEntries(await Future.wait(boxNames.map((boxName) async {
      assert(boxName.length <= 255 && boxName.isAscii,
          'Box names need to be ASCII Strings with a max length of 255.');
      boxName = boxName.toLowerCase();
      if (isBoxOpen(boxName)) {
        return MapEntry(boxName, lazyBox(boxName));
      } else {
        if (_openingBoxes.containsKey(boxName)) {
          await _openingBoxes[boxName];
          return MapEntry(boxName, lazyBox(boxName));
        }

        var completer = Completer();
        _openingBoxes[boxName] = completer.future;

        BoxBaseImpl? newBox;
        try {
          final backend = backends[boxName]!;

          newBox = LazyBoxImpl(this, boxName, defaultKeyComparator,
              defaultCompactionStrategy, backend);

          await newBox.initialize();
          _boxes[boxName] = newBox;

          completer.complete();
          return MapEntry(boxName, newBox as LazyBoxImpl);
        } catch (error, stackTrace) {
          newBox?.close();
          completer.completeError(error, stackTrace);
          rethrow;
        } finally {
          // ignore: unawaited_futures
          _openingBoxes.remove(boxName);
        }
      }
    })));
  }*/

  BoxBase<E> _getBoxInternal<E>(String name, [bool? lazy, String? collection]) {
    var lowerCaseName = name.toLowerCase();
    var box = _boxes[TupleBoxKey(lowerCaseName, collection)];
    if (box != null) {
      if ((lazy == null || box.lazy == lazy) && box.valueType == E) {
        return box as BoxBase<E>;
      } else {
        var typeName = box is LazyBox
            ? 'LazyBox<${box.valueType}>'
            : 'Box<${box.valueType}>';
        throw HiveError('The box "$lowerCaseName" is already open '
            'and of type $typeName.');
      }
    } else {
      throw HiveError('Box not found. Did you forget to call Hive.openBox()?');
    }
  }

  /// Not part of public API
  BoxBase? getBoxWithoutCheckInternal(String name, [String? collection]) {
    print('Fetching box $name');
    print(_boxes.keys);
    var lowerCaseName = name.toLowerCase();
    print(_boxes.containsKey(TupleBoxKey(lowerCaseName, collection)));
    return _boxes[TupleBoxKey(lowerCaseName, collection)];
  }

  @override
  Box<E> box<E>(String name, [String? collection]) =>
      _getBoxInternal<E>(name, false, collection) as Box<E>;

  @override
  LazyBox<E> lazyBox<E>(String name, [String? collection]) =>
      _getBoxInternal<E>(name, true, collection) as LazyBox<E>;

  @override
  bool isBoxOpen(String name, [String? collection]) {
    return _boxes.containsKey(TupleBoxKey(name.toLowerCase(), collection));
  }

  @override
  Future<void> close() {
    var closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  /// Not part of public API
  void unregisterBox(String name, [String? collection]) {
    name = name.toLowerCase();
    _openingBoxes.remove(TupleBoxKey(name, collection));
    _boxes.remove(TupleBoxKey(name, collection));
  }

  @override
  Future<void> deleteBoxFromDisk(String name,
      {String? path, String? collection}) async {
    var lowerCaseName = name.toLowerCase();
    var box = _boxes[TupleBoxKey(lowerCaseName, collection)];
    if (box != null) {
      await box.deleteFromDisk();
    } else {
      await manager.deleteBox(lowerCaseName, path ?? homePath, collection);
    }
  }

  @override
  Future<void> deleteFromDisk() {
    var deleteFutures = _boxes.values.toList().map((box) {
      return box.deleteFromDisk();
    });

    return Future.wait(deleteFutures);
  }

  @override
  List<int> generateSecureKey() {
    return _secureRandom.nextBytes(32);
  }

  @override
  Future<bool> boxExists(String name,
      {String? path, String? collection}) async {
    var lowerCaseName = name.toLowerCase();
    return await manager.boxExists(lowerCaseName, path ?? homePath, collection);
  }
}

/// tiny helper for map key management...
class TupleBoxKey {
  final String box;
  final String? collection;

  TupleBoxKey(this.box, this.collection);

  @override
  String toString() => collection == null ? box : '$collection.$box';

  @override
  int get hashCode => collection == null
      ? box.hashCode
      : [box.hashCode, collection.hashCode].hashCode;

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }
}
