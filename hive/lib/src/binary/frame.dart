import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/crypto.dart';
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

  final int length;

  const Frame(this.key, this.value, [this.length]);

  bool get deleted => value == null;

  static Frame fromBytes(
      Uint8List bytes, TypeRegistry registry, Crypto crypto) {
    var lengthBytes = Uint8List.view(bytes.buffer, 0, 4);
    var frameBytes = Uint8List.view(bytes.buffer, 4);
    checkCrc(lengthBytes, frameBytes, crypto?.keyCrc);

    var frameReader =
        BinaryReaderImpl(frameBytes, registry, frameBytes.length - 4);
    return decodeBody(frameReader, true, true, bytes.length, crypto);
  }

  static Frame bodyFromBytes(
      Uint8List bytes, TypeRegistry registry, Crypto crypto) {
    checkCrc(null, bytes, crypto?.keyCrc);
    var frameReader = BinaryReaderImpl(bytes, registry, bytes.length - 4);
    return decodeBody(frameReader, false, true, bytes.length, crypto);
  }

  static Frame decodeBody(
    BinaryReaderImpl reader,
    bool decodeKey,
    bool decodeValue,
    int frameLength,
    Crypto crypto,
  ) {
    String key;
    if (decodeKey) {
      var keyLength = reader.readByte(); // Read length of key
      key = reader.readAsciiString(keyLength); // Read key
    }

    if (reader.availableBytes == 0) {
      return Frame(key, null, frameLength);
    } else if (decodeValue) {
      dynamic value;
      if (crypto == null) {
        value = reader.read();
      } else {
        var encryptedBytes = reader.viewBytes(reader.availableBytes);
        var decryptedBytes = crypto.decrypt(encryptedBytes);
        var valueReader = BinaryReaderImpl(decryptedBytes, reader.typeRegistry);
        value = valueReader.read();
      }

      if (reader.availableBytes > 0) {
        throw HiveError('Not all bytes have been used.');
      }

      return Frame(key, value, frameLength);
    } else {
      return Frame(key, null, frameLength);
    }
  }

  static void checkCrc(
      List<int> lengthBytes, List<int> frameBytes, int keyCrc) {
    var computedCrc = keyCrc ?? 0;
    if (lengthBytes != null) {
      computedCrc = Crc32.compute(lengthBytes, crc: computedCrc);
    }
    computedCrc = Crc32.compute(frameBytes,
        crc: computedCrc, length: frameBytes.length - 4);

    var crc = bytesToUint32(frameBytes, frameBytes.length - 4);
    if (computedCrc != crc) {
      throw HiveError('Wrong checksum in hive file. Box may be corrupted.');
    }
  }

  Uint8List toBytes(
      bool writeKeyAndLength, TypeRegistry registry, Crypto crypto) {
    if (key.length > 255) {
      throw HiveError('Key must not be longer than 255 characters');
    }
    var writer = BinaryWriterImpl(registry);

    if (writeKeyAndLength) {
      writer
        ..writeByteList([0, 0, 0, 0],
            writeLength: false) // Placeholder for length
        ..writeByte(key.length) // Write key length
        ..writeAsciiString(key, writeLength: false); // Write key
    }

    if (!deleted) {
      if (crypto == null) {
        writer.write(value); // Write value
      } else {
        var valueWriter = BinaryWriterImpl(writer.typeRegistry)..write(value);
        var encryptedValue = crypto.encrypt(valueWriter.output());
        writer.writeByteList(encryptedValue, writeLength: false);
      }
    }

    writer
        .writeByteList([0, 0, 0, 0], writeLength: false); // Placeholder for CRC

    var bytes = writer.output();

    var byteData = ByteData.view(bytes.buffer);
    if (writeKeyAndLength) {
      byteData.setUint32(0, bytes.length, Endian.little); // Write length
    }

    var bytesWithoutCRC = Uint8List.view(bytes.buffer, 0, bytes.length - 4);
    var checksum = Crc32.compute(bytesWithoutCRC, crc: crypto?.keyCrc ?? 0);

    byteData.setUint32(bytes.length - 4, checksum, Endian.little);

    return bytes;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Frame) {
      return other.key == key && other.value == value && other.length == length;
    }
    return false;
  }
}

typedef ByteSource = Future<List<int>> Function(int bytes);

enum FrameValueType {
  nullT,
  intT,
  doubleT,
  boolT,
  stringT,
  byteListT,
  intListT,
  doubleListT,
  boolListT,
  stringListT,
  listT,
  mapT,
}

int bytesToUint32(List<int> bytes, [int offset = 0]) {
  return bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;
}
