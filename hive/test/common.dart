import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:hive/src/util/lock.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:pointycastle/pointycastle.dart';
import 'package:test/test.dart';

class HiveMock extends Mock implements HiveImpl {}

class RAFMock extends Mock implements RandomAccessFile {}

class LockMock extends Mock implements Lock {}

class BinaryReaderMock extends Mock implements BinaryReader {}

class BinaryWriterMock extends Mock implements BinaryWriter {}

class BackendMock extends Mock implements StorageBackend {}

class ChangeNotifierMock extends Mock implements ChangeNotifier {}

class SyncedFileMock extends Mock implements SyncedFile {}

class SecureRandomMock extends Mock implements SecureRandom {}

class BoxMock extends Mock implements Box {}

class KeystoreMock extends Mock implements Keystore {}

class KeyTransactionMock extends Mock implements KeyTransaction {}

Matcher throwsHiveError([String contains]) {
  return throwsA(
    allOf(
      isA<HiveError>(),
      predicate((HiveError e) =>
          contains == null ||
          e.toString().toLowerCase().contains(contains.toLowerCase())),
    ),
  );
}

String tempPath =
    path.join(Directory.current.path, '.dart_tool', 'test', 'tmp');
String assetsPath = path.join(Directory.current.path, 'test', 'assets');

Future<File> getTempFile([Uint8List bytes]) async {
  var name = Random().nextInt(pow(2, 32) as int);
  var file = File(path.join(tempPath, '$name.tmp'));
  await file.create(recursive: true);

  if (bytes != null) {
    await file.writeAsBytes(bytes);
  }

  return file;
}

Future<Directory> getTempDir() async {
  var name = Random().nextInt(pow(2, 32) as int);
  var dir = Directory(path.join(tempPath, '${name}_tmp'));
  await dir.create(recursive: true);
  return dir;
}

File getAssetFile(String part1, [String part2, String part3, String part4]) {
  return File(path.join(assetsPath, part1, part2, part3, part4));
}

Future<File> getTempAssetFile(String part1,
    [String part2, String part3, String part4]) async {
  var assetFile = getAssetFile(part1, part2, part3, part4);
  var tempFile = await getTempFile();

  return await assetFile.copy(tempFile.path);
}

Future<Directory> getAssetDir(String part1,
    [String part2, String part3, String part4]) async {
  var assetDir = Directory(path.join(assetsPath, part1, part2, part3, part4));
  var tempDir = await getTempDir();

  await for (var file in assetDir.list(recursive: true)) {
    if (file is File) {
      var relative = path.relative(file.path, from: assetDir.path);
      var tempFile = File(path.join(tempDir.path, relative));
      await tempFile.create(recursive: true);
      await file.copy(tempFile.path);
    }
  }

  return tempDir;
}

Future expectDirsEqual(Directory dir1, Directory dir2) {
  return _expectDirsEqual(dir1, dir2, false);
}

Future _expectDirsEqual(Directory dir1, Directory dir2, bool round2) async {
  await for (var entity in dir1.list(recursive: true)) {
    if (entity is File) {
      var fileName = path.basename(entity.path);
      var otherFile = File(path.join(dir2.path, fileName));

      var entityBytes = await entity.readAsBytes();
      var otherBytes = await otherFile.readAsBytes();
      expect(entityBytes, otherBytes);
    } else if (entity is Directory) {
      var dir2Entity =
          Directory(path.join(dir2.path, path.basename(entity.path)));
      await expectDirsEqual(entity, dir2Entity);
    }
  }

  if (!round2) {
    await _expectDirsEqual(dir2, dir1, true);
  }
}

Future expectDirEqualsAssetDir(Directory dir1, String part1,
    [String part2, String part3, String part4]) {
  var assetDir = Directory(path.join(assetsPath, part1, part2, part3, part4));
  return expectDirsEqual(dir1, assetDir);
}

Uint8List u8(List<int> list) => Uint8List.fromList(list);

class Pair<V1, V2> {
  V1 first;
  V2 second;

  Pair(this.first, this.second);
}

class ByteListReader {
  final Uint8List bytes;
  int offset = 0;

  ByteListReader(this.bytes);

  Future<Uint8List> read(int count) {
    var list = bytes.sublist(offset, offset + count);
    offset += count;
    return Future.value(list as Uint8List);
  }
}
