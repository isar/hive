import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:hive/src/util/crc32.dart';
import 'package:meta/meta.dart';
import 'package:hive/src/util/uint8_list_extension.dart';

class BinaryWriterImpl extends BinaryWriter {
  static const int _asciiMask = 0x7F;
  static const _initBufferSize = 256;

  final TypeRegistryImpl typeRegistry;
  Uint8List _buffer = Uint8List(_initBufferSize);

  ByteData _byteDataInstance;

  int _offset = 0;

  int get offset => _offset;

  ByteData get _byteData {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance;
  }

  BinaryWriterImpl(TypeRegistry typeRegistry)
      : typeRegistry = typeRegistry as TypeRegistryImpl;

  @visibleForTesting
  BinaryWriterImpl.withBuffer(this._buffer, this.typeRegistry);

  void _reserveBytes(int count) {
    if (_buffer.length - _offset < count) {
      // We will create a list in the range of 2-4 times larger than required.
      var newSize = _pow2roundup((_offset + count) * 2);
      var newBuffer = Uint8List(newSize);
      newBuffer.setRange(0, _offset, _buffer);
      _buffer = newBuffer;
      _byteDataInstance = null;
    }
  }

  void _addBytes(List<int> bytes) {
    var length = bytes.length;
    _reserveBytes(length);
    _buffer.setRange(_offset, _offset + length, bytes);
    _offset += length;
  }

  @override
  void writeByte(int byte) {
    if (byte == null) {
      throw ArgumentError.notNull();
    }
    _reserveBytes(1);
    _buffer[_offset++] = byte;
  }

  @override
  void writeWord(int value) {
    _reserveBytes(2);
    _buffer[_offset++] = value;
    _buffer[_offset++] = value >> 8;
  }

  @override
  void writeInt32(int value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    _reserveBytes(4);
    _byteData.setInt32(_offset, value, Endian.little);
    _offset += 4;
  }

  @override
  void writeUint32(int value) {
    _reserveBytes(4);
    _buffer.writeUint32(_offset, value);
    _offset += 4;
  }

  @override
  void writeInt(int value) {
    writeDouble(value.toDouble());
  }

  @override
  void writeDouble(double value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    _reserveBytes(8);
    _byteData.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }

  @override
  void writeBool(bool value) {
    writeByte(value ? 1 : 0);
  }

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    var bytes = encoder.convert(value);
    if (writeByteCount) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes);
  }

  @override
  void writeAsciiString(String value, {bool writeLength = true}) {
    var length = value.length;

    if (writeLength) {
      writeUint32(length);
    }

    _reserveBytes(length);
    for (var i = 0; i < length; i++) {
      var codeUnit = value.codeUnitAt(i);
      if ((codeUnit & ~_asciiMask) != 0) {
        throw HiveError('String contains non-ASCII characters.');
      }
      _buffer[_offset++] = codeUnit;
    }
  }

  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) {
    if (writeLength) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes);
  }

  @override
  void writeIntList(List<int> list, {bool writeLength = true}) {
    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    for (var i = 0; i < length; i++) {
      _byteData.setFloat64(_offset, list[i].toDouble(), Endian.little);
      _offset += 8;
    }
  }

  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) {
    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    for (var i = 0; i < length; i++) {
      _byteData.setFloat64(_offset, list[i], Endian.little);
      _offset += 8;
    }
  }

  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) {
    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    for (var i = 0; i < length; i++) {
      _buffer[_offset++] = list[i] ? 1 : 0;
    }
  }

  @override
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) {
    if (writeLength) {
      writeUint32(list.length);
    }
    for (var str in list) {
      var strBytes = encoder.convert(str);
      writeUint32(strBytes.length);
      _addBytes(strBytes);
    }
  }

  @override
  void writeList(List list, {bool writeLength = true}) {
    if (writeLength) {
      writeUint32(list.length);
    }
    for (var i = 0; i < list.length; i++) {
      write(list[i]);
    }
  }

  @override
  void writeMap(Map<dynamic, dynamic> map, {bool writeLength = true}) {
    if (writeLength) {
      writeUint32(map.length);
    }
    map.forEach((dynamic k, dynamic v) {
      write(k);
      write(v);
    });
  }

  void writeKey(dynamic key) {
    if (key is String) {
      writeByte(FrameKeyType.asciiStringT.index);
      writeByte(key.length);
      writeAsciiString(key, writeLength: false);
    } else {
      writeByte(FrameKeyType.uintT.index);
      writeUint32(key as int);
    }
  }

  @override
  void writeHiveList(HiveList list, {bool writeLength = true}) {
    if (writeLength) {
      writeUint32(list.length);
    }
    var box = list.box.name;
    writeByte(box.length);
    writeAsciiString(box, writeLength: false);
    for (var obj in list) {
      writeKey(obj.key);
    }
  }

  int writeFrame(Frame frame, {CryptoHelper crypto}) {
    var startOffset = _offset;
    _reserveBytes(4);
    _offset += 4; // reserve bytes for length

    writeKey(frame.key);

    if (!frame.deleted) {
      if (crypto == null) {
        write(frame.value);
      } else {
        writeEncrypted(frame.value, crypto);
      }
    }

    var frameLenght = _offset - startOffset + 4;
    _buffer.writeUint32(startOffset, frameLenght);

    var crc = Crc32.compute(
      _buffer,
      offset: startOffset,
      length: frameLenght - 4,
      crc: crypto?.keyCrc ?? 0,
    );
    writeUint32(crc);

    return frameLenght;
  }

  @override
  void write<T>(T value, {bool writeTypeId = true}) {
    if (value == null) {
      if (writeTypeId) {
        writeByte(FrameValueType.nullT.index);
      }
    } else if (value is int) {
      if (writeTypeId) {
        writeByte(FrameValueType.intT.index);
      }
      writeInt(value);
    } else if (value is double) {
      if (writeTypeId) {
        writeByte(FrameValueType.doubleT.index);
      }
      writeDouble(value);
    } else if (value is bool) {
      if (writeTypeId) {
        writeByte(FrameValueType.boolT.index);
      }
      writeBool(value);
    } else if (value is String) {
      if (writeTypeId) {
        writeByte(FrameValueType.stringT.index);
      }
      writeString(value);
    } else if (value is List) {
      _writeList(value, writeTypeId: writeTypeId);
    } else if (value is Map) {
      if (writeTypeId) {
        writeByte(FrameValueType.mapT.index);
      }
      writeMap(value);
    } else {
      var resolved = typeRegistry.findAdapterForValue(value);
      if (resolved == null) {
        throw HiveError('Cannot write, unknown type: ${value.runtimeType}. '
            'Did you forget to register an adapter?');
      }
      if (writeTypeId) {
        writeByte(resolved.typeId);
      }
      resolved.adapter.write(this, value);
    }
  }

  /// TODO remove workaround once dart-lang/sdk#39752 is published
  void _writeList(List value, {bool writeTypeId = true}) {
    if (value is HiveList) {
      if (writeTypeId) {
        writeByte(FrameValueType.hiveListT.index);
      }
      writeHiveList(value);
    } else if (value.contains(null)) {
      if (writeTypeId) {
        writeByte(FrameValueType.listT.index);
      }
      writeList(value);
    } else if (value is Uint8List) {
      if (writeTypeId) {
        writeByte(FrameValueType.byteListT.index);
      }
      writeByteList(value);
    } else if (value is List<int>) {
      if (writeTypeId) {
        writeByte(FrameValueType.intListT.index);
      }
      writeIntList(value);
    } else if (value is List<double>) {
      if (writeTypeId) {
        writeByte(FrameValueType.doubleListT.index);
      }
      writeDoubleList(value);
    } else if (value is List<bool>) {
      if (writeTypeId) {
        writeByte(FrameValueType.boolListT.index);
      }
      writeBoolList(value);
    } else if (value is List<String>) {
      if (writeTypeId) {
        writeByte(FrameValueType.stringListT.index);
      }
      writeStringList(value);
    } else {
      if (writeTypeId) {
        writeByte(FrameValueType.listT.index);
      }
      writeList(value);
    }
  }

  void writeEncrypted(dynamic value, CryptoHelper crypto,
      {bool writeTypeId = true}) {
    var valueWriter = BinaryWriterImpl(typeRegistry)
      ..write(value, writeTypeId: writeTypeId);
    var encryptedValue = crypto.encrypt(valueWriter.toBytes());
    _addBytes(encryptedValue);
  }

  Uint8List toBytes() {
    return Uint8List.view(_buffer.buffer, 0, _offset);
  }

  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}
