import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/backend/storage_backend_memory.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/util/extensions.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

import 'backend/storage_backend.dart';

/// Not part of public API
class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  final _boxes = HashMap<String, BoxBaseImpl>();
  final _openingBoxes = HashMap<String, Future>();
  final BackendManager _manager;
  final Random _secureRandom = Random.secure();

  /// Not part of public API
  @visibleForTesting
  String? homePath;

  /// Not part of public API
  HiveImpl() : _manager = BackendManager() {
    _registerDefaultAdapters();
  }

  /// Not part of public API
  @visibleForTesting
  HiveImpl.debug(this._manager) {
    _registerDefaultAdapters();
  }

  /// Not part of public API
  @visibleForTesting
  HiveImpl.test() : _manager = BackendManager() {
    registerAdapter(DateTimeAdapter<DateTime>(), internal: true);
    registerAdapter(BigIntAdapter(), internal: true);
  }

  void _registerDefaultAdapters() {
    registerAdapter(DateTimeWithTimezoneAdapter(), internal: true);
    registerAdapter(DateTimeAdapter<DateTimeWithoutTZ>(), internal: true);
    registerAdapter(BigIntAdapter(), internal: true);
  }

  @override
  void init(String path) {
    homePath = path;
  }

  Future<BoxBase<E>> _openBox<E>(
    String name,
    bool lazy,
    HiveCipher? cipher,
    KeyComparator comparator,
    CompactionStrategy compaction,
    bool recovery,
    String? path,
    Uint8List? bytes,
  ) async {
    assert(path == null || bytes == null);
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
      if (_openingBoxes.containsKey(name)) {
        await _openingBoxes[name];
        if (lazy) {
          return lazyBox(name);
        } else {
          return box(name);
        }
      }

      var completer = Completer();
      _openingBoxes[name] = completer.future;

      try {
        StorageBackend backend;
        if (bytes != null) {
          backend = StorageBackendMemory(bytes, cipher);
        } else {
          backend =
              await _manager.open(name, path ?? homePath, recovery, cipher);
        }

        BoxBaseImpl<E> newBox;
        if (lazy) {
          newBox = LazyBoxImpl<E>(this, name, comparator, compaction, backend);
        } else {
          newBox = BoxImpl<E>(this, name, comparator, compaction, backend);
        }

        await newBox.initialize();
        _boxes[name] = newBox;

        completer.complete();
        return newBox;
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
        rethrow;
      } finally {
        // ignore: unawaited_futures
        _openingBoxes.remove(name);
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
    Uint8List? bytes,
    @deprecated List<int>? encryptionKey,
  }) async {
    if (encryptionKey != null) {
      encryptionCipher = HiveAesCipher(encryptionKey);
    }
    return await _openBox<E>(name, false, encryptionCipher, keyComparator,
        compactionStrategy, crashRecovery, path, bytes) as Box<E>;
  }

  @override
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    HiveCipher? encryptionCipher,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    @deprecated List<int>? encryptionKey,
  }) async {
    if (encryptionKey != null) {
      encryptionCipher = HiveAesCipher(encryptionKey);
    }
    return await _openBox<E>(name, true, encryptionCipher, keyComparator,
        compactionStrategy, crashRecovery, path, null) as LazyBox<E>;
  }

  BoxBase<E> _getBoxInternal<E>(String name, [bool? lazy]) {
    var lowerCaseName = name.toLowerCase();
    var box = _boxes[lowerCaseName];
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
  BoxBase? getBoxWithoutCheckInternal(String name) {
    var lowerCaseName = name.toLowerCase();
    return _boxes[lowerCaseName];
  }

  @override
  Box<E> box<E>(String name) => _getBoxInternal<E>(name, false) as Box<E>;

  @override
  LazyBox<E> lazyBox<E>(String name) =>
      _getBoxInternal<E>(name, true) as LazyBox<E>;

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name.toLowerCase());
  }

  @override
  Future<void> close() {
    var closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  /// Not part of public API
  void unregisterBox(String name) {
    name = name.toLowerCase();
    _openingBoxes.remove(name);
    _boxes.remove(name);
  }

  @override
  Future<void> deleteBoxFromDisk(String name, {String? path}) async {
    var lowerCaseName = name.toLowerCase();
    var box = _boxes[lowerCaseName];
    if (box != null) {
      await box.deleteFromDisk();
    } else {
      await _manager.deleteBox(lowerCaseName, path ?? homePath);
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
  Future<bool> boxExists(String name, {String? path}) async {
    var lowerCaseName = name.toLowerCase();
    return await _manager.boxExists(lowerCaseName, path ?? homePath);
  }
}
