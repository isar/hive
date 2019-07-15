import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/frame.dart';

abstract class StorageBackend {
  String get path;

  Future<int> initialize(Map<String, BoxEntry> entries, bool cache);

  Future<dynamic> readValue(String key, int offset);

  Future<Map<String, dynamic>> readAll(Iterable<String> keys);

  Future<BoxEntry> writeFrame(Frame frame, bool cache);

  Future<List<BoxEntry>> writeFrames(List<Frame> frames, bool cache);

  Future<Map<String, BoxEntry>> compact(Map<String, BoxEntry> entries);

  Future clear();

  Future close();

  Future deleteFromDisk();
}
