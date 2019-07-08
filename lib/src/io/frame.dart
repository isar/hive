import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/io/header.dart';
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

  final FrameError error;
  final int length;

  const Frame(this.key, this.value, [this.length])
      : deleted = false,
        error = null;

  const Frame.keyOnly(this.key, [this.length])
      : value = null,
        deleted = false,
        error = null;

  const Frame.tombstone(this.key, [this.length])
      : value = null,
        error = null,
        deleted = true;

  const Frame.error(this.error)
      : key = null,
        value = null,
        deleted = null,
        length = null;

  static Future<Frame> fromReader(
    Future<List<int>> Function(int bytes) reader,
    TypeRegistry registry, {
    bool readValue = true,
    Crypto decryptor,
  }) async {
    try {
      // Read first 4 bytes to calculate length of the frame
      var lenBytes = (await reader(4)).toList();
      if (lenBytes.isEmpty) {
        return Frame.error(FrameError.eof);
      }
      var frameLength = lenBytes[0] << 24 |
          lenBytes[1] << 16 |
          lenBytes[2] << 8 |
          lenBytes[3];
      var dataLength = frameLength - 4; // Subtract length bytes

      var frameBytes = await reader(dataLength); // Read rest of frame

      if (frameBytes.length < dataLength) {
        // Could not read required amount of bytes
        return Frame.error(FrameError.corrupted);
      }

      var frameReader = BinaryReaderImpl(frameBytes, registry);
      var keyLen = frameReader.readByte(); // Read length of key
      var key = frameReader.readAsciiString(keyLen); // Read key

      Frame frame;
      if (dataLength - frameReader.usedBytes <= 4) {
        // This is a tombstone frame
        frame = Frame.tombstone(key, frameLength);
      } else if (readValue) {
        dynamic value;
        if (decryptor == null) {
          value = frameReader.read();
        } else {
          var valueBytes =
              frameReader.readBytes(frameReader.availableBytes - 4);
          var decryptedValueBytes = decryptor(Uint8List.fromList(valueBytes));
          var valueReader = BinaryReaderImpl(decryptedValueBytes, registry);
          value = valueReader.read();
        }
        frame = Frame(key, value, frameLength);
      } else {
        // Return key only frame
        frame = Frame.keyOnly(key, frameLength);
        frameReader.skip(frameReader.availableBytes - 4); // Skip to checksum
      }

      // Calculate checksum of whole frame minus checksum bytes
      var crc = frameReader.readUnsignedInt32();
      var computedCrc = Crc32.compute(lenBytes);
      computedCrc = Crc32.compute(
        frameBytes,
        crc: computedCrc,
        length: dataLength - 4,
      );

      if (crc != computedCrc) {
        return Frame.error(FrameError.wrongChecksum);
      }

      if (frameReader.usedBytes != dataLength) {
        // Reader did not use all bytes of the frame
        return Frame.error(FrameError.corrupted);
      }

      return frame;
    } catch (e) {
      print(e);
      return Frame.error(FrameError.corrupted);
    }
  }

  static Stream<Frame> streamAll(
    File file,
    TypeRegistry registry, {
    bool readValue = true,
    Crypto decryptor,
  }) async* {
    var bufferedFile = await BufferedFileReader.fromFile(file);
    await bufferedFile.skip(Header.headerLength);

    try {
      while (true) {
        var frame = await fromReader(
          (bytes) => bufferedFile.read(bytes),
          registry,
          readValue: readValue,
          decryptor: decryptor,
        );
        if (frame.error == null) {
          yield frame;
        } else {
          if (frame.error != FrameError.eof) {
            yield frame;
          }
          break;
        }
      }
    } finally {
      await bufferedFile.close();
    }
  }

  Uint8List toBytes(
    TypeRegistry registry, {
    Crypto encryptor,
  }) {
    if (key.length > 255) {
      throw HiveError("Key must not be longer than 255 characters");
    }
    var writer = BinaryWriterImpl(registry);

    var placeholderBytes = Uint8List(4);
    writer.writeBytes(placeholderBytes); // Placeholder for length
    writer.writeByte(key.length); // Write key length
    writer.writeAsciiString(key, writeLength: false); // Write key
    if (!deleted) {
      if (encryptor == null) {
        writer.write(value); // Write value
      } else {
        var valueWriter = BinaryWriterImpl(registry);
        valueWriter.write(value);
        var encryptedValue = encryptor(valueWriter.output());
        writer.writeBytes(encryptedValue);
      }
    }
    writer.writeBytes(placeholderBytes); // Placeholder for CRC

    var bytes = writer.output();

    var byteData = ByteData.view(bytes.buffer);
    byteData.setUint32(0, bytes.length); // Write length

    var bytesWithoutCRC = Uint8List.view(bytes.buffer, 0, bytes.length - 4);
    var checksum = Crc32.compute(bytesWithoutCRC);
    byteData.setUint32(bytes.length - 4, checksum);

    return bytes;
  }
}

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

enum FrameError {
  eof,
  corrupted,
  wrongChecksum,
  crypto,
}
