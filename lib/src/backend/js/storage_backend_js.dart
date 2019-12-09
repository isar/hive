import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:meta/meta.dart';

class StorageBackendJs extends StorageBackend {
  final Database db;
  final CryptoHelper crypto;

  TypeRegistry _registry;

  StorageBackendJs(this.db, this.crypto, [this._registry]);

  @override
  String get path => null;

  @override
  bool supportsCompaction = false;

  bool _isEncoded(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0x90 && bytes[1] == 0xA9;
  }

  @visibleForTesting
  dynamic encodeValue(Frame frame) {
    var value = frame.value;
    if (crypto == null) {
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
    frameWriter.writeByteList([0x90, 0xA9], writeLength: false);

    if (crypto == null) {
      frameWriter.write(value, writeTypeId: false);
    } else {
      frameWriter.writeEncrypted(value, crypto, writeTypeId: false);
    }

    var bytes = frameWriter.toBytes();
    var sublist = bytes.sublist(0, bytes.length);
    return sublist.buffer;
  }

  @visibleForTesting
  dynamic decodeValue(dynamic value) {
    if (value is ByteBuffer) {
      var bytes = Uint8List.view(value);
      if (_isEncoded(bytes)) {
        var reader = BinaryReaderImpl(bytes, _registry);
        reader.skip(2);
        if (crypto == null) {
          return reader.read();
        } else {
          return reader.readEncrypted(crypto);
        }
      } else {
        return bytes;
      }
    } else {
      return value;
    }
  }

  ObjectStore getStore(bool write, [String box = 'box']) {
    return db
        .transaction(box, write ? 'readwrite' : 'readonly')
        .objectStore(box);
  }

  Future<List<dynamic>> getKeys() {
    var completer = Completer<List<dynamic>>();
    var request = getStore(false).getAllKeys(null);
    request.onSuccess.listen((_) {
      completer.complete(request.result as List<dynamic>);
    });
    request.onError.listen((_) {
      completer.completeError(request.error);
    });
    return completer.future;
  }

  Future<Iterable<dynamic>> getValues() {
    var completer = Completer<Iterable<dynamic>>();
    var request = getStore(false).getAll(null);
    request.onSuccess.listen((_) {
      var values = (request.result as List).map(decodeValue);
      completer.complete(values);
    });
    request.onError.listen((_) {
      completer.completeError(request.error);
    });
    return completer.future;
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
    var value = await getStore(false).getObject(frame.key);
    return decodeValue(value);
  }

  @override
  Future<void> writeFrames(List<Frame> frames) async {
    var store = getStore(true);
    for (var frame in frames) {
      if (frame.deleted) {
        await store.delete(frame.key);
      } else {
        await store.put(encodeValue(frame), frame.key);
      }
    }
  }

  @override
  Future<List<Frame>> compact(Iterable<Frame> frames) {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> clear() {
    return getStore(true).clear();
  }

  @override
  Future<void> close() {
    db.close();
    return Future.value();
  }

  @override
  Future<void> deleteFromDisk() {
    return window.indexedDB.deleteDatabase(db.name);
  }
}
