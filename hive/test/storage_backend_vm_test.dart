@TestOn('vm')
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/read_write_sync.dart';
import 'package:hive/src/backend/storage_backend_vm.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/io/frame_io_helper.dart';
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
  var writer = BinaryWriterImpl(null);
  for (var frame in frames) {
    frame.toBytes(writer, null);
  }
  return writer.toBytes();
}

StorageBackendVm _getBackend({
  File file,
  File lockFile,
  bool lazy = false,
  bool crashRecovery = false,
  CryptoHelper crypto,
  FrameIoHelper ioHelper,
  TypeRegistry registry,
  ReadWriteSync sync,
  RandomAccessFile readRaf,
  RandomAccessFile writeRaf,
}) {
  return StorageBackendVm.debug(
    file ?? FileMock(),
    lockFile ?? FileMock(),
    lazy,
    crashRecovery,
    crypto,
    ioHelper ?? FrameIoHelperMock(),
    sync ?? ReadWriteSync(),
  )
    ..readRaf = readRaf
    ..writeRaf = writeRaf;
}

void main() {
  group('findHiveFileAndCleanUp', () {
    Future<void> checkFindHiveFileAndCleanUp(String folder) async {
      var hiveFileDir =
          await getAssetDir('findHiveFileAndCleanUp', folder, 'before');
      var hiveFile = await findHiveFileAndCleanUp('testBox', hiveFileDir);
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
    test('.path returns path for of open box file', () {
      var file = File('some/path');
      var backend = _getBackend(file: file);
      expect(backend.path, 'some/path');
    });

    test('.supportsCompaction is true', () {
      var backend = _getBackend();
      expect(backend.supportsCompaction, true);
    });

    group('.open()', () {
      test('readFile & writeFile', () async {
        var file = FileMock();
        var readRaf = RAFMock();
        var writeRaf = RAFMock();
        when(file.open()).thenAnswer((i) => Future.value(readRaf));
        when(file.open(mode: FileMode.writeOnlyAppend))
            .thenAnswer((i) => Future.value(writeRaf));

        var backend = _getBackend(file: file);
        await backend.open();
        expect(backend.readRaf, readRaf);
        expect(backend.writeRaf, writeRaf);
      });

      test('writeOffset', () async {
        var file = FileMock();
        var writeFile = RAFMock();
        when(file.open(mode: FileMode.writeOnlyAppend))
            .thenAnswer((i) => Future.value(writeFile));
        when(writeFile.length()).thenAnswer((i) => Future.value(123));

        var backend = _getBackend(file: file);
        await backend.open();
        expect(backend.writeOffset, 123);
      });
    });

    group('.initialize()', () {
      File getLockFile() {
        var lockFileMock = FileMock();
        when(lockFileMock.open(mode: FileMode.write))
            .thenAnswer((i) => Future.value(RAFMock()));
        return lockFileMock;
      }

      FrameIoHelper getFrameIoHelper(int recoveryOffset) {
        var testFrames = [
          Frame('key1', 'value1', length: 5, offset: 1),
          Frame('key2', 'value2', length: 4, offset: 2),
          Frame('key1', null, length: 3, offset: 3),
          Frame.deleted('key2', length: 4),
          Frame('key3', 'value3', length: 2, offset: 5),
        ];

        var helper = FrameIoHelperMock();
        when(helper.framesFromFile(any, any, any, any)).thenAnswer((i) {
          i.positionalArguments[1].addAll(testFrames);
          return Future.value(recoveryOffset);
        });
        when(helper.keysFromFile(any, any, any)).thenAnswer((i) {
          i.positionalArguments[1].addAll(testFrames);
          return Future.value(recoveryOffset);
        });
        return helper;
      }

      void runTests(bool lazy) {
        test('opens lock file and aquires lock', () async {
          var lockFile = FileMock();
          var lockRaf = RAFMock();
          when(lockFile.open(mode: FileMode.write))
              .thenAnswer((i) => Future.value(lockRaf));

          var backend = _getBackend(
            lockFile: lockFile,
            ioHelper: getFrameIoHelper(-1),
            lazy: lazy,
          );

          await backend.initialize(null, KeystoreMock());
          verify(lockRaf.lock());
        });

        test('correct offsets', () async {
          var backend = _getBackend(
            lockFile: getLockFile(),
            ioHelper: getFrameIoHelper(-1),
            lazy: lazy,
          );

          var keystore = Keystore.debug();
          await backend.initialize(null, keystore);

          expect(keystore.frames, [
            Frame('key1', null, length: 3, offset: 3),
            Frame('key3', 'value3', length: 2, offset: 5),
          ]);
          expect(keystore.deletedEntries, 2);
        });

        test('recoveryOffset with crash recovery', () async {
          var writeRaf = RAFMock();
          var backend = _getBackend(
            lockFile: getLockFile(),
            ioHelper: getFrameIoHelper(20),
            lazy: lazy,
            crashRecovery: true,
            writeRaf: writeRaf,
          );

          await backend.initialize(null, KeystoreMock());
          verify(writeRaf.truncate(20));
        });

        test('recoveryOffset without crash recovery', () async {
          var backend = _getBackend(
            lockFile: getLockFile(),
            ioHelper: getFrameIoHelper(20),
            lazy: lazy,
            crashRecovery: false,
          );

          await expectLater(() => backend.initialize(null, KeystoreMock()),
              throwsHiveError('corrupted'));
        });
      }

      group('(not lazy)', () {
        runTests(false);
      });

      group('(lazy)', () {
        runTests(true);
      });
    });

    /*test('.readValue()', () async {
      var readRaf = RAFMock();
      var frameBytes = getFrameBytes([Frame('test', 123, offset: 5)]);
      print(frameBytes);
      when(readRaf.read(frameBytes.length))
          .thenAnswer((i) => Future.value(frameBytes));

      var backend = _getBackend(readRaf: readRaf);
      var value = await backend.readValue(
        Frame('test', 123, length: frameBytes.length, offset: 5),
      );
      verifyInOrder([
        readRaf.setPosition(5),
        readRaf.read(frameBytes.length),
      ]);
      expect(value, 123);
    });*/

    group('.writeFrames()', () {
      test('writes bytes', () async {
        var frames = [Frame('key1', 'value'), Frame('key2', null)];
        var bytes = getFrameBytes(frames);

        var writeRaf = RAFMock();
        var backend = _getBackend(writeRaf: writeRaf);

        await backend.writeFrames(frames);
        verify(writeRaf.writeFrom(bytes));
      });

      test('updates offsets', () async {
        var frames = [Frame('key1', 'value'), Frame('key2', null)];

        var writeRaf = RAFMock();
        var backend = _getBackend(writeRaf: writeRaf);
        backend.writeOffset = 5;

        await backend.writeFrames(frames);
        expect(frames, [
          Frame('key1', 'value', length: 24, offset: 5),
          Frame('key2', null, length: 15, offset: 29),
        ]);
        expect(backend.writeOffset, 44);
      });

      test('resets writeOffset on error', () async {
        var writeRaf = RAFMock();
        when(writeRaf.writeFrom(any)).thenThrow('error');
        var backend = _getBackend(writeRaf: writeRaf);
        backend.writeOffset = 123;

        await expectLater(() => backend.writeFrames([Frame('key1', 'value')]),
            throwsA(anything));
        verify(writeRaf.setPosition(123));
        expect(backend.writeOffset, 123);
      });
    });

    /*group('.compact()', () {
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

      test('throws error if corrupted', () async {
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
      });
    });*/

    test('.clear()', () async {
      var writeRaf = RAFMock();
      var backend = _getBackend(writeRaf: writeRaf);
      backend.writeOffset = 111;

      await backend.clear();
      verify(writeRaf.truncate(0));
      verify(writeRaf.setPosition(0));
      expect(backend.writeOffset, 0);
    });

    test('.close()', () async {
      var readRaf = RAFMock();
      var writeRaf = RAFMock();
      var lockRaf = RAFMock();
      var lockFile = FileMock();

      var backend = _getBackend(
        lockFile: lockFile,
        readRaf: readRaf,
        writeRaf: writeRaf,
      );
      backend.lockRaf = lockRaf;

      await backend.close();
      verifyInOrder([
        readRaf.close(),
        writeRaf.close(),
        lockRaf.close(),
        lockFile.delete(),
      ]);
    });

    test('.deleteFromDisk()', () async {
      var readRaf = RAFMock();
      var writeRaf = RAFMock();
      var lockRaf = RAFMock();
      var lockFile = FileMock();
      var file = FileMock();

      var backend = _getBackend(
        file: file,
        lockFile: lockFile,
        readRaf: readRaf,
        writeRaf: writeRaf,
      );
      backend.lockRaf = lockRaf;

      await backend.deleteFromDisk();
      verifyInOrder([
        readRaf.close(),
        writeRaf.close(),
        lockRaf.close(),
        lockFile.delete(),
        file.delete()
      ]);
    });
  });
}
