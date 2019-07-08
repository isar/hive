import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/util/crc32.dart';

/// Header
/// --------------------------
/// | uint8 file version
/// | uint16 data version
/// | uint8 encrypted
/// | uint32 checksum
/// --------------------------
class Header {
  static const headerLength = 8;

  final int fileVersion;
  final int dataVersion;
  final bool encrypted;

  Header(this.fileVersion, this.dataVersion, this.encrypted);

  static Header fromBytes(Uint8List headerBytes, {Uint8List keyHash}) {
    var reader = BinaryReaderImpl(headerBytes, null);
    var fileVersion = reader.readByte();
    var dataVersion = reader.readWord();
    var encrypted = reader.readBool();
    var checksum = reader.readUnsignedInt32();
    var header = Header(fileVersion, dataVersion, encrypted);

    if (encrypted && keyHash == null) {
      throw HiveError("Cannot open encrypted box without key.");
    } else if (!encrypted && keyHash != null) {
      throw HiveError("Cannot open unencrypted box with encryption key.");
    } else if (checksum == header.calculateChecksum(keyHash)) {
      return header;
    } else {
      throw HiveError("Header checksum does not match");
    }
  }

  Uint8List toBytes({Uint8List keyHash}) {
    var writer = BinaryWriterImpl(null);
    writer.writeByte(fileVersion);
    writer.writeWord(dataVersion);
    writer.writeBool(encrypted);
    var checksum = calculateChecksum(keyHash);
    writer.writeUnsigenedInt32(checksum);
    return writer.output();
  }

  int calculateChecksum(Uint8List keyHash) {
    var bytes = Uint8List(8);
    bytes[0] = fileVersion;
    bytes[1] = dataVersion >> 8;
    bytes[2] = dataVersion & 0xFF;
    bytes[3] = encrypted ? 1 : 0;
    if (encrypted) {
      bytes[4] = keyHash[0];
      bytes[5] = keyHash[1];
      bytes[2] = keyHash[2];
      bytes[3] = keyHash[3];
    }
    return Crc32.compute(bytes);
  }
}
