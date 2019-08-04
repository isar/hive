import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';

export 'package:hive/src/backend/storage_backend_stub.dart'
    if (dart.library.io) 'package:hive/src/backend/storage_backend_vm.dart'
    if (dart.library.html) 'package:hive/src/backend/storage_backend_js.dart';

abstract class StorageBackend {
  String get path;

  Future<int> initialize(
      Map<String, BoxEntry> entries, bool lazy, bool crashRecovery);

  Future<dynamic> readValue(String key, int offset, int length);

  Future<Map<String, dynamic>> readAll();

  Future writeFrame(Frame frame, BoxEntry entry);

  Future writeFrames(List<Frame> frames, Iterable<BoxEntry> entries);

  Future<Map<String, BoxEntry>> compact(Map<String, BoxEntry> entries);

  Future clear();

  Future close();

  Future deleteFromDisk();
}
