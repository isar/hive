import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto_helper.dart';

int framesFromBytes(Uint8List bytes, List<Frame> frames, TypeRegistry registry,
    CryptoHelper crypto) {
  var reader = BinaryReaderImpl(bytes, registry);

  while (reader.availableBytes != 0) {
    var frameOffset = reader.usedBytes;

    if (reader.availableBytes < 4) {
      return frameOffset;
    }

    var lengthBytes = reader.peekBytes(4);
    var frameLength = reader.readUint32();
    if (reader.availableBytes < frameLength - 4) {
      return frameOffset;
    }
    var frameBytes = reader.peekBytes(frameLength - 4);

    if (!Frame.checkCrc(lengthBytes, frameBytes, crypto?.keyCrc)) {
      return frameOffset;
    }

    reader.limitAvailableBytes(frameLength - 8);
    var frame = Frame.decode(reader, false, frameLength, crypto);
    reader.resetLimit();
    reader.skip(4); // CRC bytes
    frames.add(frame);
  }

  return -1;
}
