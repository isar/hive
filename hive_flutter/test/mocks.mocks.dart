import 'dart:convert' as _i5;
import 'dart:typed_data' as _i2;

import 'package:hive/hive.dart' as _i4;
import 'package:hive/src/object/hive_object.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: comment_references

// ignore_for_file: unnecessary_parenthesis

class _FakeUint8List extends _i1.Fake implements _i2.Uint8List {}

class _FakeHiveList<E extends _i3.HiveObject> extends _i1.Fake
    implements _i4.HiveList<E> {}

/// A class which mocks [BinaryReader].
///
/// See the documentation for Mockito's code generation for more information.
class MockBinaryReader extends _i1.Mock implements _i4.BinaryReader {
  @override
  int get availableBytes =>
      (super.noSuchMethod(Invocation.getter(#availableBytes), 0) as int);
  @override
  int get usedBytes =>
      (super.noSuchMethod(Invocation.getter(#usedBytes), 0) as int);
  @override
  void skip(int? bytes) =>
      super.noSuchMethod(Invocation.method(#skip, [bytes]));
  @override
  int readByte() =>
      (super.noSuchMethod(Invocation.method(#readByte, []), 0) as int);
  @override
  _i2.Uint8List viewBytes(int? bytes) => (super.noSuchMethod(
          Invocation.method(#viewBytes, [bytes]), _FakeUint8List())
      as _i2.Uint8List);
  @override
  _i2.Uint8List peekBytes(int? bytes) => (super.noSuchMethod(
          Invocation.method(#peekBytes, [bytes]), _FakeUint8List())
      as _i2.Uint8List);
  @override
  int readWord() =>
      (super.noSuchMethod(Invocation.method(#readWord, []), 0) as int);
  @override
  int readInt32() =>
      (super.noSuchMethod(Invocation.method(#readInt32, []), 0) as int);
  @override
  int readUint32() =>
      (super.noSuchMethod(Invocation.method(#readUint32, []), 0) as int);
  @override
  int readInt() =>
      (super.noSuchMethod(Invocation.method(#readInt, []), 0) as int);
  @override
  double readDouble() =>
      (super.noSuchMethod(Invocation.method(#readDouble, []), 0.0) as double);
  @override
  bool readBool() =>
      (super.noSuchMethod(Invocation.method(#readBool, []), false) as bool);
  @override
  String readString(
          [int? byteCount,
          _i5.Converter<List<int>, String>? decoder =
              const _i5.Utf8Decoder()]) =>
      (super.noSuchMethod(
          Invocation.method(#readString, [byteCount, decoder]), '') as String);
  @override
  _i2.Uint8List readByteList([int? length]) => (super.noSuchMethod(
          Invocation.method(#readByteList, [length]), _FakeUint8List())
      as _i2.Uint8List);
  @override
  List<int> readIntList([int? length]) =>
      (super.noSuchMethod(Invocation.method(#readIntList, [length]), <int>[])
          as List<int>);
  @override
  List<double> readDoubleList([int? length]) => (super.noSuchMethod(
          Invocation.method(#readDoubleList, [length]), <double>[])
      as List<double>);
  @override
  List<bool> readBoolList([int? length]) =>
      (super.noSuchMethod(Invocation.method(#readBoolList, [length]), <bool>[])
          as List<bool>);
  @override
  List<String> readStringList(
          [int? length,
          _i5.Converter<List<int>, String>? decoder =
              const _i5.Utf8Decoder()]) =>
      (super.noSuchMethod(
              Invocation.method(#readStringList, [length, decoder]), <String>[])
          as List<String>);
  @override
  List<dynamic> readList([int? length]) =>
      (super.noSuchMethod(Invocation.method(#readList, [length]), <dynamic>[])
          as List<dynamic>);
  @override
  Map<dynamic, dynamic> readMap([int? length]) => (super.noSuchMethod(
          Invocation.method(#readMap, [length]), <dynamic, dynamic>{})
      as Map<dynamic, dynamic>);
  @override
  _i4.HiveList<_i3.HiveObject> readHiveList([int? length]) =>
      (super.noSuchMethod(Invocation.method(#readHiveList, [length]),
          _FakeHiveList<_i3.HiveObject>()) as _i4.HiveList<_i3.HiveObject>);
}

/// A class which mocks [BinaryWriter].
///
/// See the documentation for Mockito's code generation for more information.
class MockBinaryWriter extends _i1.Mock implements _i4.BinaryWriter {
  @override
  void writeByte(int? byte) =>
      super.noSuchMethod(Invocation.method(#writeByte, [byte]));
  @override
  void writeWord(int? value) =>
      super.noSuchMethod(Invocation.method(#writeWord, [value]));
  @override
  void writeInt32(int? value) =>
      super.noSuchMethod(Invocation.method(#writeInt32, [value]));
  @override
  void writeUint32(int? value) =>
      super.noSuchMethod(Invocation.method(#writeUint32, [value]));
  @override
  void writeInt(int? value) =>
      super.noSuchMethod(Invocation.method(#writeInt, [value]));
  @override
  void writeDouble(double? value) =>
      super.noSuchMethod(Invocation.method(#writeDouble, [value]));
  @override
  void writeBool(bool? value) =>
      super.noSuchMethod(Invocation.method(#writeBool, [value]));
  @override
  void writeString(String? value,
          {bool? writeByteCount = true,
          _i5.Converter<String, List<int>>? encoder =
              const _i5.Utf8Encoder()}) =>
      super.noSuchMethod(Invocation.method(#writeString, [value],
          {#writeByteCount: writeByteCount, #encoder: encoder}));
  @override
  void writeByteList(List<int>? bytes, {bool? writeLength = true}) =>
      super.noSuchMethod(Invocation.method(
          #writeByteList, [bytes], {#writeLength: writeLength}));
  @override
  void writeIntList(List<int>? list, {bool? writeLength = true}) =>
      super.noSuchMethod(Invocation.method(
          #writeIntList, [list], {#writeLength: writeLength}));
  @override
  void writeDoubleList(List<double>? list, {bool? writeLength = true}) =>
      super.noSuchMethod(Invocation.method(
          #writeDoubleList, [list], {#writeLength: writeLength}));
  @override
  void writeBoolList(List<bool>? list, {bool? writeLength = true}) =>
      super.noSuchMethod(Invocation.method(
          #writeBoolList, [list], {#writeLength: writeLength}));
  @override
  void writeStringList(List<String>? list,
          {bool? writeLength = true,
          _i5.Converter<String, List<int>>? encoder =
              const _i5.Utf8Encoder()}) =>
      super.noSuchMethod(Invocation.method(#writeStringList, [list],
          {#writeLength: writeLength, #encoder: encoder}));
  @override
  void writeList(List<dynamic>? list, {bool? writeLength = true}) =>
      super.noSuchMethod(
          Invocation.method(#writeList, [list], {#writeLength: writeLength}));
  @override
  void writeMap(Map<dynamic, dynamic>? map, {bool? writeLength = true}) =>
      super.noSuchMethod(
          Invocation.method(#writeMap, [map], {#writeLength: writeLength}));
  @override
  void writeHiveList(_i4.HiveList<_i3.HiveObject>? list,
          {bool? writeLength = true}) =>
      super.noSuchMethod(Invocation.method(
          #writeHiveList, [list], {#writeLength: writeLength}));
  @override
  void write<T>(T? value, {bool? writeTypeId = true}) => super.noSuchMethod(
      Invocation.method(#write, [value], {#writeTypeId: writeTypeId}));
}
