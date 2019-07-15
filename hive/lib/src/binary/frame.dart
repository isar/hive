import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/util/crc32.dart';

/// Frame
/// --------------------------
/// | uint32 frame length (including these 4 bytes and checksum)
/// --------------------------
/// | uint8 key length
/// | List<uint8> ascii key
/// -------------------------- (optional)
/// | uint8 value type
/// | List<uint8> value bytes
/// --------------------------
/// | uint32 checksum
/// --------------------------
///
/// int
/// --------------------------
/// | int64 value
/// --------------------------
///
/// double
/// --------------------------
/// | float64 value
/// --------------------------
///
/// bool
/// --------------------------
/// | uint8 value
/// --------------------------
///
/// string
/// --------------------------
/// | uint16 length
/// | List<uint8> char
/// --------------------------
///
/// list
/// --------------------------
/// | uint16 length
/// | uint8 value1 type
/// | List<uint8> value1 bytes
/// | ...
/// --------------------------
///
/// map
/// --------------------------
/// | uint16 length
/// | uint8 key1 type
/// | List<uint8> key1 bytes
/// | uint8 value1 type
/// | List<uint8> value1 bytes
/// | ...
/// --------------------------
class Frame {
  static const maxFrameLength = 1000 * 64;

  final String key;
  final dynamic value;
  final bool deleted;

  final int length;

  const Frame(this.key, this.value, [this.length]) : deleted = false;

  const Frame.keyOnly(this.key, [this.length])
      : value = null,
        deleted = false;

  const Frame.tombstone(this.key, [this.length])
      : value = null,
        deleted = true;

  static Future<Frame> fromBytes(
      ByteSource source, TypeRegistry registry, CryptoHelper crypto) async {
    var lengthBytes = (await source(4)).toList();
    if (lengthBytes.isEmpty) return null;

    var frameLength = bytesToUint32(lengthBytes);
    var frameBytes = await source(frameLength - 4);
    checkCrc(lengthBytes, frameBytes, crypto?.keyCrc);
    var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
    return decodeBody(frameReader, true, true, crypto);
  }

  static Frame valueOnlyFromBytes(
      Uint8List bytes, TypeRegistry registry, CryptoHelper crypto) {
    checkCrc([], bytes, crypto?.keyCrc);
    var frameReader = BinaryReaderImpl(bytes, registry, bytes.length - 4);
    return decodeBody(frameReader, false, true, crypto);
  }

  static Frame decodeBody(
    BinaryReaderImpl reader,
    bool decodeKey,
    bool decodeValue,
    CryptoHelper crypto,
  ) {
    var frameLength = reader.availableBytes + 8;

    String key;
    if (decodeKey) {
      var keyLength = reader.readByte(); // Read length of key
      key = reader.readAsciiString(keyLength); // Read key
    }

    if (reader.availableBytes == 0) {
      return Frame.tombstone(key, frameLength);
    } else if (decodeValue) {
      dynamic value;
      if (crypto == null) {
        value = reader.read();
      } else {
        var encryptedBytes = reader.viewBytes(reader.availableBytes);
        var decryptedBytes = crypto.decryptor(encryptedBytes);
        var valueReader = BinaryReaderImpl(decryptedBytes, reader.typeRegistry);
        value = valueReader.read();
      }

      if (reader.availableBytes > 0) {
        throw HiveError('Not all bytes have been used.');
      }

      return Frame(key, value, frameLength);
    } else {
      return Frame.keyOnly(key, frameLength);
    }
  }

  static void checkCrc(
      List<int> lengthBytes, List<int> frameBytes, int keyCrc) {
    var computedCrc = Crc32.compute(lengthBytes, crc: keyCrc ?? 0);
    computedCrc = Crc32.compute(frameBytes,
        crc: computedCrc, length: frameBytes.length - 4);

    var crc = bytesToUint32(frameBytes, frameBytes.length - 4);
    if (computedCrc != crc) {
      throw HiveError('Wrong checksum in hive file. Box may be corrupted.');
    }
  }

  Uint8List toBytes(
      TypeRegistry registry, bool writeKeyAndLength, CryptoHelper crypto) {
    if (key.length > 255) {
      throw HiveError('Key must not be longer than 255 characters');
    }
    var writer = BinaryWriterImpl(registry);

    if (writeKeyAndLength) {
      writer.writeBytes([0, 0, 0, 0]); // Placeholder for length
      encodeBody(writer, true, crypto);
    }

    writer.writeBytes([0, 0, 0, 0]); // Placeholder for CRC

    var bytes = writer.output();

    var byteData = ByteData.view(bytes.buffer);
    if (writeKeyAndLength) {
      byteData.setUint32(0, bytes.length, Endian.little); // Write length
    }

    var bytesWithoutCRC = Uint8List.view(bytes.buffer, 0, bytes.length - 4);
    var checksum = Crc32.compute(bytesWithoutCRC, crc: crypto?.keyCrc);

    byteData.setUint32(bytes.length - 4, checksum, Endian.little);

    return bytes;
  }

  void encodeBody(
    BinaryWriterImpl frameWriter,
    bool writeKey,
    CryptoHelper crypto,
  ) {
    if (writeKey) {
      frameWriter.writeByte(key.length); // Write key length
      frameWriter.writeAsciiString(key, writeLength: false); // Write key
    }

    if (!deleted) {
      if (crypto == null) {
        frameWriter.write(value); // Write value
      } else {
        var valueWriter = BinaryWriterImpl(frameWriter.typeRegistry);
        valueWriter.write(value);
        var encryptedValue = crypto.encryptor(valueWriter.output());
        frameWriter.writeBytes(encryptedValue);
      }
    }
  }

  @override
  bool operator ==(dynamic f) {
    if (f is Frame) {
      return f.key == key &&
          f.value == value &&
          f.deleted == deleted &&
          f.length == length;
    }
    return false;
  }
}

typedef ByteSource = Future<List<int>> Function(int bytes);

enum FrameValueType {
  null_,
  int_,
  double_,
  bool_,
  string_,
  int_list_,
  double_list_,
  bool_list_,
  string_list_,
  list_,
  map_,
}

int bytesToUint32(List<int> bytes, [offset = 0]) {
  return bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;
}
