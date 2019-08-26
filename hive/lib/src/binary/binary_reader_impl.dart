import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';

class BinaryReaderImpl extends BinaryReader {
  final Uint8List _buffer;
  final int _bufferLength;
  final ByteData _data;
  final TypeRegistry typeRegistry;
  int _offset = 0;

  BinaryReaderImpl(this._buffer, this.typeRegistry, [int bufferLength])
      : _bufferLength = bufferLength ?? _buffer.length,
        _data = ByteData.view(_buffer.buffer, _buffer.offsetInBytes,
            bufferLength ?? _buffer.length);

  int get _bufferOffset => _buffer.offsetInBytes + _offset;

  @override
  int get availableBytes => _bufferLength - _offset;

  @override
  int get usedBytes => _offset;

  Uint8List get buffer => _buffer;

  void _requireBytes(int bytes) {
    if (_bufferLength - _offset < bytes) {
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
    var view = Uint8List.view(_buffer.buffer, _bufferOffset, bytes);
    _offset += bytes;
    return view;
  }

  @override
  int readWord() {
    _requireBytes(2);
    return _buffer[_offset++] | _buffer[_offset++] << 8;
  }

  @override
  int readInt32() {
    _requireBytes(4);
    var value = _data.getInt32(_offset, Endian.little);
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
    var value = _data.getFloat64(_offset, Endian.little);
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
    byteCount ??= readWord();
    var view = viewBytes(byteCount);
    return decoder.convert(view);
  }

  @override
  String readAsciiString([int length]) {
    length ??= readWord();
    var view = viewBytes(length);
    var str = String.fromCharCodes(view);
    return str;
  }

  @override
  Uint8List readByteList([int length]) {
    length ??= readWord();
    _requireBytes(length);
    var byteList = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return byteList as Uint8List;
  }

  @override
  List<int> readIntList([int length]) {
    length ??= readWord();
    _requireBytes(length * 8);
    var list = <int>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = _data.getFloat64(_offset, Endian.little).toInt();
      _offset += 8;
    }
    return list;
  }

  @override
  List<double> readDoubleList([int length]) {
    length ??= readWord();
    _requireBytes(length * 8);
    var list = <double>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = _data.getFloat64(_offset, Endian.little);
      _offset += 8;
    }
    return list;
  }

  @override
  List<bool> readBoolList([int length]) {
    length ??= readWord();
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
    length ??= readWord();
    var list = <String>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = readString(null, decoder);
    }
    return list;
  }

  @override
  List readList([int length]) {
    length ??= readWord();
    var list = <dynamic>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = read();
    }
    return list;
  }

  @override
  Map readMap([int length]) {
    length ??= readWord();
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
        throw HiveError('Cannot read, unknown typeId: $typeId.'
            ' Did you forget to register an adapter?');
      }
      return resolved.adapter.read(this);
    }
  }
}
