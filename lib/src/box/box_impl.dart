export 'box_impl_stub.dart'
    if (dart.library.io) 'box_impl_vm.dart'
    if (dart.library.html) 'box_impl_js.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

abstract class BoxImpl extends TypeRegistryImpl implements Box {
  final HiveImpl hive;
  final String name;
  final BoxOptions options;
  final CryptoHelper _crypto;
  final _streamController = StreamController<BoxEvent>.broadcast();

  bool _open = true;

  BoxImpl(this.hive, this.name, this.options)
      : _crypto =
            options.encrypted ? CryptoHelper(options.encryptionKey) : null,
        super(hive);

  @override
  bool get isOpen => _open;

  @protected
  Crypto get encryptor => _crypto?.encryptor;

  @protected
  Crypto get decryptor => _crypto?.decryptor;

  @protected
  Uint8List get keyHash => _crypto?.keyHash;

  @override
  Future operator [](String key) => get(key);

  @protected
  void checkOpen() {
    if (!_open) {
      throw HiveError("Box has already been closed.");
    }
  }

  @protected
  void checkKey(String key) {
    if (key == null) {
      throw HiveError("Key must not be null");
    }
  }

  @override
  Stream<BoxEvent> watch({String key}) {
    if (key != null) {
      return _streamController.stream.where((it) => it.key == key);
    } else {
      return _streamController.stream;
    }
  }

  @protected
  void notifyChange(String key, dynamic value, bool deleted) {
    _streamController.add(BoxEvent(key, value, deleted));
  }

  @override
  @mustCallSuper
  Future<void> close({bool compact = false}) async {
    _open = false;
    await _streamController.close();
    hive.unregisterBox(name);
  }

  @override
  @mustCallSuper
  Future<void> deleteFromDisk() async {
    _open = false;
    hive.unregisterBox(name);
    await _streamController.close();
  }
}
