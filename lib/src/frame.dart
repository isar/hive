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

  static Future<Frame> fromBytes(ByteSource source, TypeRegistry registry,
      bool readKey, Crypto decryptor) async {
    var lengthBytes = (await source(4)).toList();
    if (lengthBytes.isEmpty) return null;

    var frameLength = bytesToUint32(lengthBytes);
    var frameBytes = await source(frameLength - 4);
    checkCrc(lengthBytes, frameBytes);
    var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
    return decodeBody(frameReader, readKey, true, decryptor);
  }

  static Frame decodeBody(
    BinaryReaderImpl frameReader,
    bool decodeKey,
    bool decodeValue,
    Crypto decryptor,
  ) {
    var frameLength = frameReader.availableBytes + 8;

    String key;
    if (decodeKey) {
      var keyLength = frameReader.readByte(); // Read length of key
      key = frameReader.readAsciiString(keyLength); // Read key
    }

    Frame frame;
    if (frameReader.availableBytes == 0) {
      // This is a tombstone frame
      frame = Frame.tombstone(key, frameLength);
    } else if (decodeValue) {
      dynamic value;
      if (decryptor == null) {
        value = frameReader.read();
        if (frameReader.availableBytes > 0) {
          throw HiveError("Not all bytes have been used.");
        }
      } else {
        var encryptedBytes = frameReader.viewBytes(frameReader.availableBytes);
        var decryptedBytes = decryptor(encryptedBytes);
        var valueReader =
            BinaryReaderImpl(decryptedBytes, frameReader.typeRegistry);
        value = valueReader.read();
        if (valueReader.availableBytes > 0) {
          throw HiveError("Not all bytes have been used.");
        }
      }
      frame = Frame(key, value, frameLength);
    } else {
      // Return key only frame
      frame = Frame.keyOnly(key, frameLength);
    }

    return frame;
  }

  static void checkCrc(List<int> lengthBytes, List<int> frameBytes) {
    var computedCrc = Crc32.compute(lengthBytes);
    computedCrc = Crc32.compute(frameBytes,
        crc: computedCrc, length: frameBytes.length - 4);
    var crc = bytesToUint32(frameBytes, frameBytes.length - 4);
    if (computedCrc != crc) {
      throw HiveError("Wrong checksum in hive file. Box may be corrupted.");
    }
  }

  Uint8List toBytes(TypeRegistry registry, bool writeKey, Crypto encryptor) {
    if (key.length > 255) {
      throw HiveError("Key must not be longer than 255 characters");
    }
    var writer = BinaryWriterImpl(registry);

    writer.writeBytes([0, 0, 0, 0]); // Placeholder for length
    encodeBody(writer, writeKey, encryptor);
    writer.writeBytes([0, 0, 0, 0]); // Placeholder for CRC

    var bytes = writer.output();

    var byteData = ByteData.view(bytes.buffer);
    byteData.setUint32(0, bytes.length, Endian.little); // Write length

    var bytesWithoutCRC = Uint8List.view(bytes.buffer, 0, bytes.length - 4);
    var checksum = Crc32.compute(bytesWithoutCRC);
    byteData.setUint32(bytes.length - 4, checksum, Endian.little);

    return bytes;
  }

  void encodeBody(
    BinaryWriterImpl frameWriter,
    bool writeKey,
    Crypto encryptor,
  ) {
    if (writeKey) {
      frameWriter.writeByte(key.length); // Write key length
      frameWriter.writeAsciiString(key, writeLength: false); // Write key
    }

    if (!deleted) {
      if (encryptor == null) {
        frameWriter.write(value); // Write value
      } else {
        var valueWriter = BinaryWriterImpl(frameWriter.typeRegistry);
        valueWriter.write(value);
        var encryptedValue = encryptor(valueWriter.output());
        frameWriter.writeBytes(encryptedValue);
      }
    }
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
