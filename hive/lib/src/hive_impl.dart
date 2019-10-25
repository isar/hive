import 'dart:collection';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/big_int_adapter.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/backend/storage_backend_memory.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

import 'backend/storage_backend.dart';

class HiveImpl extends TypeRegistryImpl implements HiveInterface {
  final _boxes = HashMap<String, Box>();

  String _homePath;

  HiveImpl() {
    registerInternal(DateTimeAdapter(), 16);
    registerInternal(BigIntAdapter(), 17);
  }

  @override
  void init(String path) {
    _homePath = path;

    _boxes.clear();
  }

  @visibleForTesting
  CryptoHelper getCryptoHelper(List<int> encryptionKey) {
    if (encryptionKey == null) return null;
    if (encryptionKey.length != 32 ||
        encryptionKey.any((it) => it < 0 || it > 255)) {
      throw ArgumentError(
          'The encryption key has to be a 32 byte (256 bit) array.');
    }
    return CryptoHelper(Uint8List.fromList(encryptionKey));
  }

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    List<int> encryptionKey,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    bool crashRecovery = true,
    bool lazy = false,
    String path,
  }) async {
    if (isBoxOpen(name)) {
      var openedBox = box<E>(name);
      if (openedBox.lazy != lazy) {
        throw HiveError(
            'The box "$name" is already open. You cannot open a box as lazy '
            'and non-lazy at the same time.');
      }
      return openedBox;
    } else {
      var cs = compactionStrategy ?? defaultCompactionStrategy;
      var crypto = getCryptoHelper(encryptionKey);
      var boxPath = path ?? _homePath;
      var backend =
          await openBackend(name, boxPath, lazy, crashRecovery, crypto);
      BoxBase<E> box;
      if (lazy) {
        if (E == dynamic) {
          var lazyBox = LazyBoxImpl(this, name, keyComparator, cs, backend);
          box = lazyBox as BoxBase<E>;
        } else {
          throw HiveError('Lazy boxes do not support type arguments.');
        }
      } else {
        box = BoxImpl<E>(this, name, keyComparator, cs, backend);
      }
      await box.initialize();
      _boxes[name.toLowerCase()] = box;

      return box;
    }
  }

  @override
  Future<Box<E>> openBoxFromBytes<E>(
    String name,
    Uint8List bytes, {
    List<int> encryptionKey,
    KeyComparator keyComparator,
  }) async {
    if (isBoxOpen(name)) {
      return box(name);
    } else {
      var crypto = getCryptoHelper(encryptionKey);
      var backend = StorageBackendMemory(bytes, crypto);
      var box = BoxImpl<E>(this, name, keyComparator, null, backend);
      await box.initialize();
      _boxes[name.toLowerCase()] = box;

      return box;
    }
  }

  @override
  Box<E> box<E>(String name) {
    if (isBoxOpen(name)) {
      var box = _boxes[name.toLowerCase()] as BoxBase;
      if (box.valueType == E) {
        return box as Box<E>;
      } else {
        throw HiveError('The box "$name" is already open and of type '
            'Box<${box.valueType}>. You cannot open the same box as Box<$E>.');
      }
    } else {
      throw HiveError('Box not found. Did you forget to call Hive.openBox()?');
    }
  }

  Box getBoxInternal(String name) => _boxes[name.toLowerCase()];

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

  void unregisterBox(String name) {
    _boxes.remove(name.toLowerCase());
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
    var secureRandom = CryptoHelper.createSecureRandom();
    return secureRandom.nextBytes(32);
  }
}
