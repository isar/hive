import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/util/crc32.dart';

class Frame {
  final dynamic key;
  final dynamic value;
  final bool deleted;
  final bool lazy;

  int length;
  int offset = -1;

  Frame(this.key, this.value, {this.length, this.offset = -1})
      : lazy = false,
        deleted = false,
        assert(
            (key is int && key >= 0 && key < 4294967295) ||
                (key is String && key.length <= 255),
            'Unsupported key');

  Frame.deleted(this.key, {this.length})
      : value = null,
        lazy = false,
        deleted = true,
        offset = -1,
        assert(
            (key is int && key >= 0 && key < 4294967295) ||
                (key is String && key.length <= 255),
            'Unsupported key');

  Frame.lazy(this.key, {this.length, this.offset = -1})
      : value = null,
        lazy = true,
        deleted = false,
        assert(
            (key is int && key >= 0 && key < 4294967295) ||
                (key is String && key.length <= 255),
            'Unsupported key');

  static Frame fromBytes(BinaryReaderImpl reader, CryptoHelper crypto) {
    if (reader.availableBytes < 4) return null;

    var frameLength = reader.peekUint32();
    if (frameLength < 8) {
      throw HiveError('This is an iternal error. Please open an issue on '
          'GitHub and provide steps to reproduce this problem if possible.');
    }

    if (reader.availableBytes < frameLength) {
      return null;
    }

    var bytes = reader.viewBytes(frameLength - 4);
    var computedCrc = Crc32.compute(bytes, crc: crypto?.keyCrc ?? 0);
    var crc = reader.readUint32();

    if (computedCrc != crc) {
      return null;
    }

    reader.unskip(frameLength - 4); // Everything but length bytes

    reader.limitAvailableBytes(frameLength - 8);
    var frame = decode(reader, false, crypto);
    frame.length = frameLength;
    reader.resetLimit();

    reader.skip(4); // CRC bytes
    return frame;
  }

  static Frame decode(
    BinaryReaderImpl reader,
    bool lazy,
    CryptoHelper crypto,
  ) {
    dynamic key;
    var keyType = reader.readByte();
    if (keyType == FrameKeyType.uintT.index) {
      key = reader.readUint32();
    } else if (keyType == FrameKeyType.asciiStringT.index) {
      var keyLength = reader.readByte(); // Read length of key
      key = reader.readAsciiString(keyLength); // Read key
    } else {
      throw HiveError('Unsupported key type. Frame might be corrupted.');
    }

    if (reader.availableBytes == 0) {
      return Frame.deleted(key);
    } else if (lazy) {
      return Frame.lazy(key);
    } else {
      var value = decodeValue(reader, crypto);
      return Frame(key, value);
    }
  }

  static dynamic decodeValue(
    BinaryReaderImpl reader,
    CryptoHelper crypto,
  ) {
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

    return value;
  }

  int toBytes(BinaryWriterImpl writer, CryptoHelper crypto) {
    var initialOffset = writer.offset;

    // Placeholder for length
    writer.writeByteList([0, 0, 0, 0], writeLength: false);

    var localKey = key;
    if (localKey is String) {
      writer
        ..writeByte(FrameKeyType.asciiStringT.index)
        ..writeByte(localKey.length) // Write key length
        ..writeAsciiString(localKey, writeLength: false); // Write key

    } else {
      writer
        ..writeByte(FrameKeyType.uintT.index)
        ..writeUint32(localKey as int); // Write key
    }

    if (!deleted) {
      encodeValue(writer, crypto);
    }

    var writtenBytesCount = writer.offset - initialOffset;
    var writtenBytes = writer.view(initialOffset, writtenBytesCount);
    var lengthIncludingCrc = writtenBytesCount + 4;

    writtenBytes[0] = lengthIncludingCrc;
    writtenBytes[1] = lengthIncludingCrc >> 8;
    writtenBytes[2] = lengthIncludingCrc >> 16;
    writtenBytes[3] = lengthIncludingCrc >> 24;

    var checksum = Crc32.compute(writtenBytes, crc: crypto?.keyCrc ?? 0);
    writer.writeUint32(checksum);

    return lengthIncludingCrc;
  }

  void encodeValue(BinaryWriterImpl writer, CryptoHelper crypto) {
    if (crypto == null) {
      writer.write(value); // Write value
    } else {
      var valueWriter = BinaryWriterImpl(writer.typeRegistry)..write(value);
      var encryptedValue = crypto.encrypt(valueWriter.toBytes());
      writer.writeByteList(encryptedValue, writeLength: false);
    }
  }

  Frame toLazy() {
    return Frame.lazy(
      key,
      length: length,
      offset: offset,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Frame) {
      return key == other.key &&
          value == other.value &&
          length == other.length &&
          deleted == other.deleted;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    if (deleted) {
      return 'Frame.deleted(key: $key, length: $length)';
    } else if (lazy) {
      return 'Frame.lazy(key: $key, length: $length, offset: $offset)';
    } else {
      return 'Frame(key: $key, value: $value, '
          'length: $length, offset: $offset)';
    }
  }
}

enum FrameKeyType {
  uintT,
  asciiStringT,
}

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
