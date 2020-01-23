import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto/padded_cipher.dart';

class FrameHelper {
  int framesFromBytes(Uint8List bytes, Keystore keystore, TypeRegistry registry,
      PaddedCipher cipher) {
    var reader = BinaryReaderImpl(bytes, registry);

    while (reader.availableBytes != 0) {
      var frameOffset = reader.usedBytes;

      var frame = reader.readFrame(
        cipher: cipher,
        lazy: false,
        frameOffset: frameOffset,
      );
      if (frame == null) return frameOffset;

      keystore.insert(frame, notify: false);
    }

    return -1;
  }
}
