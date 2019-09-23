import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

class BinaryReaderImpl extends BinaryReader {
  final Uint8List _buffer;
  final ByteData _byteData;
  final int _bufferLength;
  final TypeRegistryImpl typeRegistry;

  int _bufferLimit;
  int _offset = 0;

  BinaryReaderImpl(this._buffer, TypeRegistry typeRegistry, [int bufferLength])
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes),
        _bufferLength = bufferLength ?? _buffer.length,
        _bufferLimit = bufferLength ?? _buffer.length,
        typeRegistry = typeRegistry as TypeRegistryImpl;

  @override
  int get availableBytes => _bufferLimit - _offset;

  @override
  int get usedBytes => _offset;

  void limitAvailableBytes(int bytes) {
    _requireBytes(bytes);
    _bufferLimit = _offset + bytes;
  }

  void resetLimit() {
    _bufferLimit = _bufferLength;
  }

  void _requireBytes(int bytes) {
    if (_offset + bytes > _bufferLimit) {
      throw RangeError('Not enough bytes available.');
    }
  }

  @override
  void skip(int bytes) {
    _requireBytes(bytes);
    _offset += bytes;
  }

  @override
  int readByte() {
    _requireBytes(1);
    return _buffer[_offset++];
  }

  @override
  Uint8List viewBytes(int bytes) {
    _requireBytes(bytes);
    var view =
        Uint8List.view(_buffer.buffer, _buffer.offsetInBytes + _offset, bytes);
    _offset += bytes;
    return view;
  }

  @override
  Uint8List peekBytes(int bytes) {
    _requireBytes(bytes);
    return Uint8List.view(
        _buffer.buffer, _buffer.offsetInBytes + _offset, bytes);
  }

  @override
  int readWord() {
    _requireBytes(2);
    return _buffer[_offset++] | _buffer[_offset++] << 8;
  }

  @override
  int readInt32() {
    _requireBytes(4);
    var value = _byteData.getInt32(_offset, Endian.little);
    _offset += 4;
    return value;
  }

  @override
  int readUint32() {
    _requireBytes(4);
    return _buffer[_offset++] |
        _buffer[_offset++] << 8 |
        _buffer[_offset++] << 16 |
        _buffer[_offset++] << 24;
  }

  @override
  int readInt() {
    return readDouble().toInt();
  }

  @override
  double readDouble() {
    _requireBytes(8);
    var value = _byteData.getFloat64(_offset, Endian.little);
    _offset += 8;
    return value;
  }

  @override
  bool readBool() {
    _requireBytes(1);
    return _buffer[_offset++] > 0;
  }

  @override
  String readString(
      [int byteCount,
      Converter<List<int>, String> decoder = BinaryReader.utf8Decoder]) {
    byteCount ??= readUint32();
    var view = viewBytes(byteCount);
    return decoder.convert(view);
  }

  @override
  String readAsciiString([int length]) {
    length ??= readUint32();
    var view = viewBytes(length);
    var str = String.fromCharCodes(view);
    return str;
  }

  @override
  Uint8List readByteList([int length]) {
    length ??= readUint32();
    _requireBytes(length);
    var byteList = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return byteList;
  }

  @override
  List<int> readIntList([int length]) {
    length ??= readUint32();
    _requireBytes(length * 8);
    var list = <int>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(_offset, Endian.little).toInt();
      _offset += 8;
    }
    return list;
  }

  @override
  List<double> readDoubleList([int length]) {
    length ??= readUint32();
    _requireBytes(length * 8);
    var list = <double>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(_offset, Endian.little);
      _offset += 8;
    }
    return list;
  }

  @override
  List<bool> readBoolList([int length]) {
    length ??= readUint32();
    _requireBytes(length);
    var list = <bool>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = _buffer[_offset++] > 0;
    }
    return list;
  }

  @override
  List<String> readStringList(
      [int length,
      Converter<List<int>, String> decoder = BinaryReader.utf8Decoder]) {
    length ??= readUint32();
    var list = <String>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = readString(null, decoder);
    }
    return list;
  }

  @override
  List readList([int length]) {
    length ??= readUint32();
    var list = <dynamic>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = read();
    }
    return list;
  }

  @override
  Map readMap([int length]) {
    length ??= readUint32();
    var map = <dynamic, dynamic>{};
    for (var i = 0; i < length; i++) {
      var key = read();
      var value = read();
      map[key] = value;
    }
    return map;
  }

  @override
  dynamic read([int typeId]) {
    typeId ??= readByte();
    if (typeId < FrameValueType.values.length) {
      var typeEnum = FrameValueType.values[typeId];
      switch (typeEnum) {
        case FrameValueType.nullT:
          return null;
        case FrameValueType.intT:
          return readInt();
        case FrameValueType.doubleT:
          return readDouble();
        case FrameValueType.boolT:
          return readBool();
        case FrameValueType.stringT:
          return readString();
        case FrameValueType.byteListT:
          return readByteList();
        case FrameValueType.intListT:
          return readIntList();
        case FrameValueType.doubleListT:
          return readDoubleList();
        case FrameValueType.boolListT:
          return readBoolList();
        case FrameValueType.stringListT:
          return readStringList();
        case FrameValueType.listT:
          return readList();
        case FrameValueType.mapT:
          return readMap();
      }
    } else {
      var resolved = typeRegistry.findAdapterForTypeId(typeId);
      if (resolved == null) {
        throw HiveError('Cannot read, unknown typeId: $typeId. '
            'Did you forget to register an adapter?');
      }
      return resolved.adapter.read(this);
    }
  }
}
