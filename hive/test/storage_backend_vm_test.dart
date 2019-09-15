@TestOn('vm')
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/backend/storage_backend_vm.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/io/frame_io_helper.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

class FrameIoHelperMock extends Mock implements FrameIoHelper {}

const testMap = {
  'SomeKey': 123,
  'AnotherKey': ['Just', 456, 'a', 333, 'List'],
  'Random Double list': [1.0, 2.0, 10.0, double.infinity],
  'Unicode:': '👋',
  'Null': null,
  'LastKey': true,
};

Uint8List getFrameBytes(List<Frame> frames) {
  var bytes = BytesBuilder();
  for (var frame in frames) {
    bytes.add(frame.toBytes(null, null));
  }
  return bytes.toBytes() as Uint8List;
}

void main() {
  group('findHiveFileAndCleanUp', () {
    Future<void> checkFindHiveFileAndCleanUp(String folder) async {
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
    group('.initialize()', () {
      test('not lazy', () async {
        var ioHelper = FrameIoHelperMock();
        when(ioHelper.framesFromFile(any, any, any, any)).thenAnswer((i) async {
          i.positionalArguments[1].addAll([
            Frame('key1', 'value1', length: 5, offset: 1),
            Frame('key2', 'value2', length: 4, offset: 2),
            Frame('key1', null, length: 3, offset: 3),
            Frame.deleted('key2', length: 4),
            Frame('key3', 'value3', length: 2, offset: 5),
          ]);
          return null;
        });

        var backend = StorageBackendVm.debug(SyncedFileMock(), null, ioHelper);

        var keystore = Keystore();
        await backend.initialize(null, keystore, false, false);

        expect(keystore.frames.values, [
          Frame('key1', null, length: 3, offset: 3),
          Frame('key3', 'value3', length: 2, offset: 5),
        ]);
        expect(keystore.deletedEntries, 2);
      });

      test('lazy', () async {
        var ioHelper = FrameIoHelperMock();
        when(ioHelper.keysFromFile(any, any, any)).thenAnswer((i) async {
          i.positionalArguments[1].addAll([
            Frame.lazy('key1', length: 5, offset: 1),
            Frame.lazy('key2', length: 4, offset: 2),
            Frame.lazy('key1', length: 3, offset: 3),
            Frame.deleted('key2', length: 4),
            Frame.lazy('key3', length: 2, offset: 5),
          ]);
          return null;
        });

        var backend = StorageBackendVm.debug(SyncedFileMock(), null, ioHelper);

        var keystore = Keystore();
        await backend.initialize(null, keystore, true, false);

        expect(keystore.frames, {
          'key1': Frame.lazy('key1', length: 3, offset: 3),
          'key3': Frame.lazy('key3', length: 2, offset: 5),
        });
        expect(keystore.deletedEntries, 2);
      });
    });

    test('.readValue()', () async {
      var file = SyncedFileMock();
      var frameBytes = getFrameBytes([Frame('test', 123)]);
      when(file.readAt(5, frameBytes.length))
          .thenAnswer((i) async => frameBytes);

      var backend = StorageBackendVm(file, null);
      var value = await backend.readValue(
        Frame('key', null, length: frameBytes.length, offset: 5),
      );
      expect(value, 123);
    });

    test('.writeFrame()', () async {
      var mockFile = SyncedFileMock();
      when(mockFile.write(any)).thenAnswer((_) => Future.value(123));

      var backend = StorageBackendVm(mockFile, null);

      var frame = Frame('key', 'value');
      var bytes = frame.toBytes(null, null);
      await backend.writeFrame(frame);
      verify(mockFile.write(bytes));
      expect(frame, Frame('key', 'value', length: bytes.length, offset: 123));
    });

    test('.writeFrames()', () async {
      var mockFile = SyncedFileMock();
      when(mockFile.write(any)).thenAnswer((_) => Future.value(10));

      var backend = StorageBackendVm(mockFile, null);

      var frame1 = Frame('key1', 'value');
      var frame2 = Frame('key2', null);
      var bytes1 = frame1.toBytes(null, null);
      var bytes2 = frame2.toBytes(null, null);
      var bytes = [...bytes1, ...bytes2];

      await backend.writeFrames([frame1, frame2]);
      verify(mockFile.write(bytes));
      expect(frame1, Frame('key1', 'value', length: bytes1.length));
      expect(
          frame2,
          Frame('key2', null,
              length: bytes2.length, offset: 10 + bytes1.length));
    });

    group('.compact()', () {
      //TODO improve this test
      test('check compaction', () async {
        var bytes = BytesBuilder();
        var comparisonBytes = BytesBuilder();
        var entries = <String, Frame>{};

        void addFrame(String key, dynamic val, [bool keep = false]) {
          var frameBytes = Frame(key, val).toBytes(null, null);
          if (keep) {
            entries[key] = Frame(key, val,
                length: frameBytes.length, offset: bytes.length);
            comparisonBytes.add(frameBytes);
          } else {
            entries.remove(key);
          }
          bytes.add(frameBytes);
        }

        for (var i = 0; i < 1000; i++) {
          for (var key in testMap.keys) {
            addFrame(key, testMap[key]);
            addFrame(key, null);
          }
        }

        for (var key in testMap.keys) {
          addFrame(key, 12345);
          addFrame(key, null);
          addFrame(key, 'This is a test');
          addFrame(key, testMap[key], true);
        }

        var boxFile = await getTempFile();
        await boxFile.writeAsBytes(bytes.toBytes());

        var syncedFile = SyncedFile(boxFile.path);
        await syncedFile.open();
        var backend = StorageBackendVm(syncedFile, null);

        await backend.compact(entries.values);

        var compactedBytes = await File(backend.path).readAsBytes();
        expect(compactedBytes, comparisonBytes.toBytes());

        await backend.close();
      });

      /*test('throws error if corrupted', () async {
        var bytes = BytesBuilder();
        var boxFile = await getTempFile(); 
        var syncedFile = SyncedFile(boxFile.path);
        await syncedFile.open();

        var box = BoxImplVm(
            HiveImpl(), path.basename(boxFile.path), BoxOptions(), syncedFile);
        await box.put('test', true);
        await box.put('test2', 'hello');
        await box.put('test', 'world');

        await syncedFile.truncate(await boxFile.length() - 1);

        expect(() => box.compact(), throwsHiveError('unexpected eof'));
      });*/
    });

    test('.clear()', () {
      var mockFile = SyncedFileMock();
      var backend = StorageBackendVm(mockFile, null);
      backend.clear();
      verify(mockFile.truncate(0));
    });

    test('.close()', () {
      var mockFile = SyncedFileMock();
      var backend = StorageBackendVm(mockFile, null);
      backend.close();
      verify(mockFile.close());
    });

    test('.delete()', () {
      var mockFile = SyncedFileMock();
      var backend = StorageBackendVm(mockFile, null);
      backend.deleteFromDisk();
      verify(mockFile.delete());
    });
  });
}
