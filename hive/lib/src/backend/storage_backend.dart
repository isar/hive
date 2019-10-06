import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';

export 'package:hive/src/backend/storage_backend_stub.dart'
    if (dart.library.io) 'package:hive/src/backend/storage_backend_vm.dart'
    if (dart.library.html) 'package:hive/src/backend/storage_backend_js.dart';

abstract class StorageBackend {
  String get path;

  bool get supportsCompaction;

  Future<void> initialize(TypeRegistry registry, Keystore keystore);

  Future<dynamic> readValue(Frame frame);

  Future<void> writeFrames(List<Frame> frames);

  Future<void> compact(Iterable<Frame> frames);

  Future<void> clear();

  Future<void> close();

  Future<void> deleteFromDisk();
}
