@TestOn('vm')

import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_vm.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

const testMap = {
  "SomeKey": 123,
  "AnotherKey": ["Just", 456, "a", 333, "List"],
  "Random Double list": [1.0, 2.0, 10.0, double.infinity],
  "Unicode:": "👋",
  "Null": null,
  "LastKey": true,
};

Uint8List getFrameBytes(List<Frame> frames) {
  var bytes = BytesBuilder();
  for (var frame in frames) {
    bytes.add(frame.toBytes(true, null, null));
  }
  return bytes.toBytes();
}

void main() {
  group('findHiveFileAndCleanUp', () {
    void checkFindHiveFileAndCleanUp(String folder) async {
      var hiveFileDir =
          await getAssetDir('findHiveFileAndCleanUp', folder, 'before');
      var hiveFile = await findHiveFileAndCleanUp('testBox', hiveFileDir.path);
      expect(hiveFile.path, path.join(hiveFileDir.path, 'testBox.hive'));
      await expectDirEqualsAssetDir(
          hiveFileDir, 'findHiveFileAndCleanUp', folder, 'after');
    }

    test('no hive file', () async {
      await checkFindHiveFileAndCleanUp('no_hive_file');
    });

    test('hive file', () async {
      await checkFindHiveFileAndCleanUp('hive_file');
    });

    test('hive file and compact file', () async {
      await checkFindHiveFileAndCleanUp('hive_file_and_compact_file');
    });

    test('only compact file', () async {
      await checkFindHiveFileAndCleanUp('only_compact_file');
    });
  });

  group('StorageBackendVm', () {
    test('.readValue()', () async {
      var file = SyncedFileMock();
      var frameBytes = getFrameBytes([Frame('test', 123)]);
      when(file.readAt(5, frameBytes.length))
          .thenAnswer((i) async => frameBytes);

      var backend = StorageBackendVm(file, null);
      var value = await backend.readValue('key', 5, frameBytes.length);
      expect(value, 123);
    });

    test('.readAll()', () async {
      var file = SyncedFile((await getTempFile()).path);
      await file.open();

      var frameBytes =
          getFrameBytes([Frame('key1', 1), Frame('key2', 2), Frame('key3', 3)]);
      await file.write(frameBytes);

      var backend = StorageBackendVm(file, null);
      var map = await backend.readAll(null);
      expect(map, {'key1': 1, 'key2': 2, 'key3': 3});
    });

    test('.writeFrame()', () async {
      var mockFile = SyncedFileMock();
      when(mockFile.write(any)).thenAnswer((_) => Future.value(123));

      var backend = StorageBackendVm(mockFile, null);

      var frame = Frame("key", "value");
      var bytes = frame.toBytes(true, null, null);

      var entry = await backend.writeFrame(frame, true);
      verify(mockFile.write(bytes));
      expect(entry, BoxEntry('value', 123, bytes.length));

      entry = await backend.writeFrame(frame, false);
      verify(mockFile.write(bytes));
      expect(entry, BoxEntry(null, 123, bytes.length));
    });

    test('.writeFrames()', () async {
      var mockFile = SyncedFileMock();
      when(mockFile.write(any)).thenAnswer((_) => Future.value(10));

      var backend = StorageBackendVm(mockFile, null);

      var frame1 = Frame("key", "value");
      var frame2 = Frame("key", null);
      var bytes1 = frame1.toBytes(true, null, null);
      var bytes2 = frame2.toBytes(true, null, null);
      var bytes = [...bytes1, ...bytes2];

      var entries = await backend.writeFrames([frame1, frame2], true);
      verify(mockFile.write(bytes));
      expect(entries, [
        BoxEntry('value', 10, bytes1.length),
        BoxEntry(null, 10 + bytes1.length, bytes2.length)
      ]);

      entries = await backend.writeFrames([frame1, frame2], false);
      verify(mockFile.write(bytes));
      expect(entries, [
        BoxEntry(null, 10, bytes1.length),
        BoxEntry(null, 10 + bytes1.length, bytes2.length)
      ]);
    });

    group('.compact()', () {
      test('check compactation', () async {
        var bytes = BytesBuilder();
        var comparisonBytes = BytesBuilder();
        var entries = Map<String, BoxEntry>();

        void addFrame(String key, dynamic val, [bool keep = false]) {
          var frameBytes = Frame(key, val).toBytes(true, null, null);
          if (keep) {
            entries[key] = BoxEntry(val, bytes.length, frameBytes.length);
            comparisonBytes.add(frameBytes);
          } else {
            entries.remove(key);
          }
          bytes.add(frameBytes);
        }

        for (int i = 0; i < 1000; i++) {
          for (var key in testMap.keys) {
            addFrame(key, testMap[key]);
            addFrame(key, null);
          }
        }

        for (var key in testMap.keys) {
          addFrame(key, 12345);
          addFrame(key, null);
          addFrame(key, "This is a test");
          addFrame(key, testMap[key], true);
        }

        var boxFile = await getTempFile();
        await boxFile.writeAsBytes(bytes.toBytes());

        var syncedFile = SyncedFile(boxFile.path);
        await syncedFile.open();
        var backend = StorageBackendVm(syncedFile, null);

        await backend.compact(entries);

        var compactedBytes = await File(backend.path).readAsBytes();
        expect(compactedBytes, comparisonBytes.toBytes());

        await backend.close();
      });

      /*test("throws error if corrupted", () async {
        var boxFile = await getTempFile();
        var syncedFile = SyncedFile(boxFile.path);
        await syncedFile.open();

        var box = BoxImplVm(
            HiveImpl(), path.basename(boxFile.path), BoxOptions(), syncedFile);
        await box.put("test", true);
        await box.put("test2", "hello");
        await box.put("test", "world");

        await syncedFile.truncate(await boxFile.length() - 1);

        expect(() => box.compact(), throwsHiveError("unexpected eof"));
      });*/
    });
  });
}
