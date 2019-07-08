import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/io/frame.dart';

class BinaryReaderImpl extends BinaryReader {
  final ByteData _data;
  final TypeRegistry typeRegistry;
  int _offset = 0;

  BinaryReaderImpl(Uint8List buffer, this.typeRegistry)
      : _data =
            ByteData.view(buffer.buffer, buffer.offsetInBytes, buffer.length);

  int get _bufferOffset => _data.offsetInBytes + _offset;

  @override
  int get availableBytes {
    return _data.lengthInBytes - _offset;
  }

  @override
  int get usedBytes => _offset;

  @override
  void skip(int bytes) {
    if (availableBytes < bytes) {
      throw RangeError("Not enough bytes available.");
    }
    _offset += bytes;
  }

  @override
  int readByte() {
    return _data.getUint8(_offset++);
  }

  @override
  List<int> viewBytes(int bytes) {
    var view = Uint8List.view(_data.buffer, _bufferOffset, bytes);
    _offset += bytes;
    return view;
  }

  @override
  List<int> readBytes(int bytes) {
    return viewBytes(bytes).toList();
  }

  @override
  int readWord() {
    var value = _data.getUint16(_offset);
    _offset += 2;
    return value;
  }

  @override
  int readInt32() {
    var value = _data.getInt32(_offset);
    _offset += 4;
    return value;
  }

  @override
  int readUnsignedInt32() {
    var value = _data.getUint32(_offset);
    _offset += 4;
    return value;
  }

  @override
  int readInt() {
    var value = _data.getInt64(_offset);
    _offset += 8;
    return value;
  }

  @override
  double readDouble() {
    var value = _data.getFloat64(_offset);
    _offset += 8;
    return value;
  }

  @override
  bool readBool() {
    return _data.getUint8(_offset++) > 0;
  }

  @override
  String readString(
      [int byteCount,
      Converter<List<int>, String> decoder = BinaryReader.utf8Decoder]) {
    if (byteCount == null) {
      byteCount = readWord();
    }
    var view = viewBytes(byteCount);
    return decoder.convert(view);
  }

  @override
  String readAsciiString([int length]) {
    if (length == null) {
      length = readWord();
    }
    var view = viewBytes(length);
    var str = String.fromCharCodes(view);
    return str;
  }

  @override
  List<int> readIntList([int length]) {
    if (length == null) {
      length = readWord();
    }
    var list = List<int>(length);
    for (int i = 0; i < length; i++) {
      list[i] = _data.getInt64(_offset);
      _offset += 8;
    }
    return list;
  }

  @override
  List<double> readDoubleList([int length]) {
    if (length == null) {
      length = readWord();
    }
    var list = List<double>(length);
    for (int i = 0; i < length; i++) {
      list[i] = _data.getFloat64(_offset);
      _offset += 8;
    }
    return list;
  }

  @override
  List<bool> readBoolList([int length]) {
    if (length == null) {
      length = readWord();
    }
    var view = viewBytes(length);
    var list = List<bool>(length);
    for (int i = 0; i < length; i++) {
      list[i] = view[i] > 0;
    }
    return list;
  }

  @override
  List<String> readStringList(
      [int length,
      Converter<List<int>, String> decoder = BinaryReader.utf8Decoder]) {
    if (length == null) {
      length = readWord();
    }
    var list = List<String>(length);
    for (int i = 0; i < length; i++) {
      list[i] = readString(null, decoder);
    }
    return list;
  }

  @override
  List readList([int length]) {
    if (length == null) {
      length = readWord();
    }
    var list = List(length);
    for (int i = 0; i < length; i++) {
      list[i] = read();
    }
    return list;
  }

  @override
  Map readMap([int length]) {
    if (length == null) {
      length = readWord();
    }
    Map map = Map();
    for (int i = 0; i < length; i++) {
      var key = read();
      var value = read();
      map[key] = value;
    }
    return map;
  }

  @override
  dynamic read([int typeId]) {
    if (typeId == null) {
      typeId = readByte();
    }
    if (typeId < FrameValueType.values.length) {
      var typeEnum = FrameValueType.values[typeId];
      switch (typeEnum) {
        case FrameValueType.null_:
          return null;
        case FrameValueType.int_:
          return readInt();
        case FrameValueType.double_:
          return readDouble();
        case FrameValueType.bool_:
          return readBool();
        case FrameValueType.string_:
          return readString();
        case FrameValueType.int_list_:
          return readIntList();
        case FrameValueType.double_list_:
          return readDoubleList();
        case FrameValueType.bool_list_:
          return readBoolList();
        case FrameValueType.string_list_:
          return readStringList();
        case FrameValueType.list_:
          return readList();
        case FrameValueType.map_:
          return readMap();
      }
    } else {
      var resolved = typeRegistry.findAdapterForTypeId(typeId);
      if (resolved == null) {
        throw HiveError("Cannot read, unknown typeId '$typeId'.");
      }
      return resolved.adapter.read(this);
    }
  }
}
