import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';

abstract class RandomAccessBuffer {
  /// Get the current write offset
  int get writeOffset;

  /// Get the current length in bytes
  int get length;

  /// Perform the recovery check
  /// Throws an [HiveError] on box corruption
  void recoveryCheck(
      TypeRegistry typeRegistry, Keystore? keystore, HiveCipher? cipher);

  /// Read a [Frame] from the [RandomAccessBuffer]
  Future<dynamic> read(
      Frame frame, TypeRegistry typeRegistry, HiveCipher? cipher);

  /// Write a list of [Frame] to the [RandomAccessBuffer]
  Future<void> write(
      List<Frame> frames, TypeRegistry typeRegistry, HiveCipher? cipher);

  /// Clear the buffer and reset the write offset
  Future<void> clear();
}
