import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';

export 'package:hive/src/backend/storage_backend_vm.dart'
    if (dart.library.html) 'package:hive/src/backend/storage_backend_js.dart';

abstract class StorageBackend {
  String get path;

  bool get supportsCompaction;

  Future<int> initialize(TypeRegistry registry, Map<dynamic, BoxEntry> entries,
      bool lazy, bool crashRecovery);

  Future<dynamic> readValue(dynamic key, int offset, int length);

  Future<Map<dynamic, dynamic>> readAll();

  Future<void> writeFrame(Frame frame, BoxEntry entry);

  Future<void> writeFrames(List<Frame> frames, Iterable<BoxEntry> entries);

  Future<Map<dynamic, BoxEntry>> compact(Map<dynamic, BoxEntry> entries);

  Future<void> clear();

  Future<void> close();

  Future<void> deleteFromDisk();
}
