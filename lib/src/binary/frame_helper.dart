import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';

class FrameHelper {
  int framesFromBytes(Uint8List bytes, Keystore keystore, TypeRegistry registry,
      CryptoHelper crypto) {
    var reader = BinaryReaderImpl(bytes, registry);

    while (reader.availableBytes != 0) {
      var frameOffset = reader.usedBytes;

      var frame = Frame.fromBytes(reader, crypto);
      if (frame == null) return frameOffset;

      frame.offset = frameOffset;
      keystore.insert(frame, notify: false);
    }

    return -1;
  }
}
