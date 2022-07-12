import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/web_worker/web_worker_interface.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:meta/meta.dart';

/// Handles all IndexedDB related tasks
class StorageBackendWebWorker extends StorageBackend {
  static const _bytePrefix = [0x90, 0xA9];
  final WebWorkerInterface _interface;
  final String _db;
  final HiveCipher? _cipher;
  final String objectStoreName;

  TypeRegistry _registry;

  /// Not part of public API
  StorageBackendWebWorker(
      this._interface, this._db, this._cipher, this.objectStoreName,
      [this._registry = TypeRegistryImpl.nullImpl]);

  @override
  String? get path => null;

  @override
  bool supportsCompaction = false;

  bool _isEncoded(Uint8List bytes) {
    return bytes.length >= _bytePrefix.length &&
        bytes[0] == _bytePrefix[0] &&
        bytes[1] == _bytePrefix[1];
  }

  /// Not part of public API
  @visibleForTesting
  dynamic encodeValue(Frame frame) {
    var value = frame.value;
    if (_cipher == null) {
      if (value == null) {
        return value;
      } else if (value is Uint8List) {
        if (!_isEncoded(value)) {
          return value.buffer;
        }
      } else if (value is num ||
          value is bool ||
          value is String ||
          value is List<num> ||
          value is List<bool> ||
          value is List<String>) {
        return value;
      }
    }

    var frameWriter = BinaryWriterImpl(_registry);
    frameWriter.writeByteList(_bytePrefix, writeLength: false);

    if (_cipher == null) {
      frameWriter.write(value);
    } else {
      frameWriter.writeEncrypted(value, _cipher!);
    }

    var bytes = frameWriter.toBytes();
    var sublist = bytes.sublist(0, bytes.length);
    return sublist.buffer;
  }

  /// Not part of public API
  @visibleForTesting
  dynamic decodeValue(dynamic value) {
    if (value is ByteBuffer) {
      var bytes = Uint8List.view(value);
      if (_isEncoded(bytes)) {
        var reader = BinaryReaderImpl(bytes, _registry);
        reader.skip(2);
        if (_cipher == null) {
          return reader.read();
        } else {
          return reader.readEncrypted(_cipher!);
        }
      } else {
        return bytes;
      }
    } else {
      return value;
    }
  }

  /// Not part of public API
  @visibleForTesting
  Future<List<dynamic>> getKeys({bool cursor = false}) {
    return _interface.query('getAllKeys', _db, objectStoreName);
  }

  /// Not part of public API
  @visibleForTesting
  Future<Iterable<dynamic>> getValues({bool cursor = false}) async {
    final values = await _interface.query<Iterable<dynamic>>(
        'getAll', _db, objectStoreName);
    return values.map(decodeValue);
  }

  @override
  Future<int> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    _registry = registry;
    var keys = await getKeys();
    if (!lazy) {
      var i = 0;
      var values = await getValues();
      for (var value in values) {
        var key = keys[i++];
        keystore.insert(Frame(key, value), notify: false);
      }
    } else {
      for (var key in keys) {
        keystore.insert(Frame.lazy(key), notify: false);
      }
    }

    return 0;
  }

  @override
  Future<dynamic> readValue(Frame frame) async {
    var value = await _interface.query('get', _db, objectStoreName, frame.key);
    return decodeValue(value);
  }

  @override
  Future<void> writeFrames(List<Frame> frames) async {
    // TODO(TheOneWithTheBraid): implement as transaction
    final deleted = frames.where((element) => element.deleted).toList();
    final notDeleted = frames.where((element) => !element.deleted).toList();

    if (deleted.isNotEmpty) {
      await _interface.query('deleteKey', _db, objectStoreName,
          deleted.map((e) => e.key).toList());
    }
    if (notDeleted.isNotEmpty) {
      await _interface.query(
          'put',
          _db,
          objectStoreName,
          notDeleted.map((e) => e.key).toList(),
          notDeleted.map(encodeValue).toList());
    }
  }

  @override
  Future<List<Frame>> compact(Iterable<Frame> frames) {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> clear() async {
    await _interface.query('clear', _db, objectStoreName);
  }

  @override
  Future<void> close() async {
    await _interface.query('close', _db, objectStoreName);
  }

  @override
  Future<void> deleteFromDisk() async {
    await _interface.query('delete', _db, objectStoreName);
  }

  @override
  Future<void> flush() => Future.value();
}
