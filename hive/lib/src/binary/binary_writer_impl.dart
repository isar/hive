import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_writer_buffer.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:meta/meta.dart';

class BinaryWriterImpl extends BinaryWriter {
  static const int _asciiMask = 0x7F;
  final TypeRegistry typeRegistry;
  BinaryWriterBuffer _buffer;

  BinaryWriterImpl(this.typeRegistry) : _buffer = BinaryWriterBuffer();

  @visibleForTesting
  BinaryWriterImpl.withBuffer(this._buffer, this.typeRegistry);

  @override
  int get writtenBytes => _buffer.writtenBytes;

  @override
  void writeByte(int byte) {
    if (byte == null) {
      throw ArgumentError.notNull();
    }
    var offset = _buffer.useBytes(1);
    _buffer.byteData.setUint8(offset, byte);
  }

  @override
  void writeWord(int value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    var offset = _buffer.useBytes(2);
    _buffer.byteData.setUint16(offset, value, Endian.little);
  }

  @override
  void writeInt32(int value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    var offset = _buffer.useBytes(4);
    _buffer.byteData.setInt32(offset, value, Endian.little);
  }

  @override
  void writeUint32(int value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    var offset = _buffer.useBytes(4);
    _buffer.byteData.setUint32(offset, value, Endian.little);
  }

  @override
  void writeInt(int value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    writeDouble(value.toDouble());
  }

  @override
  void writeDouble(double value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    var offset = _buffer.useBytes(8);
    _buffer.byteData.setFloat64(offset, value, Endian.little);
  }

  @override
  void writeBool(bool value) {
    if (value == null) {
      throw ArgumentError.notNull();
    }
    var offset = _buffer.useBytes(1);
    _buffer.byteData.setUint8(offset, value ? 1 : 0);
  }

  @override
  void writeString(String value,
      {bool writeByteCount = true,
      Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder}) {
    var bytes = encoder.convert(value);
    if (writeByteCount) {
      writeWord(bytes.length);
    }
    _buffer.addBytes(bytes);
  }

  @override
  void writeAsciiString(String value, {bool writeLength = true}) {
    var length = value.length;
    var bytes = Uint8List(length);

    if (writeLength) {
      writeWord(length);
    }

    for (var i = 0; i < length; i++) {
      var codeUnit = value.codeUnitAt(i);
      if ((codeUnit & ~_asciiMask) != 0) {
        throw HiveError('String contains non-ASCII characters.');
      }
      bytes[i] = codeUnit;
    }

    _buffer.addBytes(bytes);
  }

  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) {
    if (writeLength) {
      writeWord(bytes.length);
    }
    _buffer.addBytes(bytes);
  }

  @override
  void writeIntList(List<int> list, {bool writeLength = true}) {
    if (writeLength) {
      writeWord(list.length);
    }
    var offset = _buffer.useBytes(list.length * 8);
    for (int i = 0; i < list.length; i++) {
      _buffer.byteData
          .setFloat64(offset + i * 8, list[i].toDouble(), Endian.little);
    }
  }

  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) {
    if (writeLength) {
      writeWord(list.length);
    }
    var offset = _buffer.useBytes(list.length * 8);
    for (int i = 0; i < list.length; i++) {
      _buffer.byteData.setFloat64(offset + i * 8, list[i], Endian.little);
    }
  }

  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) {
    if (writeLength) {
      writeWord(list.length);
    }
    var offset = _buffer.useBytes(list.length);
    for (int i = 0; i < list.length; i++) {
      _buffer.byteData.setUint8(offset + i, list[i] ? 1 : 0);
    }
  }

  @override
  void writeStringList(List<String> list,
      {bool writeLength = true,
      Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder}) {
    if (writeLength) {
      writeWord(list.length);
    }
    var bytes = BytesBuilder(copy: false);
    for (int i = 0; i < list.length; i++) {
      var str = list[i];
      var strBytes = encoder.convert(str);
      bytes.addByte(strBytes.length);
      bytes.addByte(strBytes.length << 8);
      bytes.add(strBytes);
    }
    _buffer.addBytes(bytes.toBytes());
  }

  @override
  void writeList(List list, {bool writeLength = true}) {
    if (writeLength) {
      writeWord(list.length);
    }
    for (int i = 0; i < list.length; i++) {
      write(list[i]);
    }
  }

  @override
  void writeMap(Map map, {bool writeLength = true}) {
    if (writeLength) {
      writeWord(map.length);
    }
    map.forEach((k, v) {
      write(k);
      write(v);
    });
  }

  @override
  void write(dynamic value, {bool writeTypeId = true}) {
    if (value == null) {
      if (writeTypeId) {
        writeByte(FrameValueType.null_.index);
      }
    } else if (value is int) {
      if (writeTypeId) {
        writeByte(FrameValueType.int_.index);
      }
      writeInt(value);
    } else if (value is double) {
      if (writeTypeId) {
        writeByte(FrameValueType.double_.index);
      }
      writeDouble(value);
    } else if (value is bool) {
      if (writeTypeId) {
        writeByte(FrameValueType.bool_.index);
      }
      writeBool(value);
    } else if (value is String) {
      if (writeTypeId) {
        writeByte(FrameValueType.string_.index);
      }
      writeString(value);
    } else if (value is List) {
      if (value.contains(null)) {
        if (writeTypeId) {
          writeByte(FrameValueType.list_.index);
        }
        writeList(value);
      } else if (value is Uint8List) {
        if (writeTypeId) {
          writeByte(FrameValueType.byte_list_.index);
        }
        writeByteList(value);
      } else if (value is List<int>) {
        if (writeTypeId) {
          writeByte(FrameValueType.int_list_.index);
        }
        writeIntList(value);
      } else if (value is List<double>) {
        if (writeTypeId) {
          writeByte(FrameValueType.double_list_.index);
        }
        writeDoubleList(value);
      } else if (value is List<bool>) {
        if (writeTypeId) {
          writeByte(FrameValueType.bool_list_.index);
        }
        writeBoolList(value);
      } else if (value is List<String>) {
        if (writeTypeId) {
          writeByte(FrameValueType.string_list_.index);
        }
        writeStringList(value);
      } else {
        if (writeTypeId) {
          writeByte(FrameValueType.list_.index);
        }
        writeList(value);
      }
    } else if (value is Map) {
      if (writeTypeId) {
        writeByte(FrameValueType.map_.index);
      }
      writeMap(value);
    } else {
      var resolved = typeRegistry.findAdapterForType(value.runtimeType);
      if (resolved == null) {
        throw HiveError('Cannot write, unknown type: ${value.runtimeType}.');
      }
      if (writeTypeId) {
        writeByte(resolved.typeId);
      }
      resolved.adapter.write(this, value);
    }
  }

  Uint8List output() {
    var bytes = Uint8List(writtenBytes);
    _buffer.writeTo(bytes);
    return bytes;
  }

  Uint8List outputAndClear() {
    var list = output();
    _buffer = BinaryWriterBuffer();
    return list;
  }
}
