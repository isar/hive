import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/binary/frame.dart';

abstract class StorageBackend {
  String get path;

  Future<int> initialize(Map<String, BoxEntry> entries, bool lazy);

  Future<dynamic> readValue(String key, int offset, int length);

  Future<Map<String, dynamic>> readAll(Iterable<String> keys);

  Future<BoxEntry> writeFrame(Frame frame, bool lazy);

  Future<List<BoxEntry>> writeFrames(List<Frame> frames, bool lazy);

  Future<Map<String, BoxEntry>> compact(Map<String, BoxEntry> entries);

  Future clear();

  Future close();

  Future deleteFromDisk();
}
