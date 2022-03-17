import 'dart:async';
import 'dart:html';
import 'dart:js_util';

import 'dart:math';

import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

class WebWorkerInterface {
  static const _bytePrefix = [0x90, 0xA9];

  TypeRegistry _registry;
  final HiveCipher? _cipher;

  static const href =
      'packages/hive/src/backend/js/web_worker/web_worker.dart.js';

  final Worker _worker = Worker(href);
  final Random _random = Random();

  final Map<double, Completer> _queries = {};

  WebWorkerInterface(this._cipher,
      [this._registry = TypeRegistryImpl.nullImpl]) {
    _worker.onMessage.listen(_handleMessage);
  }

  Future<T> query<T>(List<dynamic> queue) {
    final label = _random.nextDouble();
    final completer = Completer<T>();
    _queries[label] = completer;
    queue = queue.map((parameter) {
      if (parameter is List) {
        return parameter.map(encodeValue).toList();
      } else {
        return encodeValue(parameter);
      }
    }).toList();
    _worker.postMessage(jsify([label, ...queue]));
    return completer.future;
  }

  void _handleMessage(MessageEvent event) {
    final label = event.data['label'];
    final completer = _queries[label];
    var response = event.data['response'];
    if (response is List) {
      response = response.map(decodeValue).toList();
    } else {
      response = decodeValue(response);
    }
    completer?.complete(response);
    _queries.remove(label);
  }

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

  bool _isEncoded(Uint8List bytes) {
    return bytes.length >= _bytePrefix.length &&
        bytes[0] == _bytePrefix[0] &&
        bytes[1] == _bytePrefix[1];
  }

  dynamic encodeValue(dynamic value) {
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

  void setRegistry(TypeRegistry registry) {
    _registry = registry;
  }
}
