import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/frame.dart';

Future<List<Frame>> readFrameKeysFromFile(
    File file, TypeRegistry registry) async {
  var bufferedFile = await BufferedFileReader.fromFile(file);
  var frames = List<Frame>();
  try {
    while (true) {
      var lengthBytes = (await bufferedFile.read(4)).toList();
      if (lengthBytes.isEmpty) break;

      var frameLength = bytesToUint32(lengthBytes);
      var frameBytes = await bufferedFile.read(frameLength - 4);
      Frame.checkCrc(lengthBytes, frameBytes);
      var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
      var frame = Frame.decodeBody(frameReader, true, false, null);
      frames.add(frame);
    }
  } finally {
    await bufferedFile.close();
  }

  return frames;
}

Future<List<Frame>> readFramesFromFile(
    File file, TypeRegistry registry, Crypto decryptor) async {
  var bytes = await file.readAsBytes();
  var reader = BinaryReaderImpl(bytes, registry);
  var frames = List<Frame>();
  while (true) {
    if (reader.availableBytes == 0) break;

    var lengthBytes = reader.readBytes(4);
    var frameLength = bytesToUint32(lengthBytes);
    var frameBytes = reader.viewBytes(frameLength - 4);
    Frame.checkCrc(lengthBytes, frameBytes);
    var frameReader = BinaryReaderImpl(frameBytes, registry, frameLength - 8);
    var frame = Frame.decodeBody(frameReader, true, true, decryptor);
    frames.add(frame);
  }

  return frames;
}
