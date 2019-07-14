@TestOn('vm')

import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/frame.dart';
import 'package:hive/src/io/synced_file.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

const testMap = {
  'SomeKey': 123,
  'AnotherKey': ['Just', 456, 'a', 333, 'List'],
  'Random Double list': [1.0, 2.0, 10.0, double.infinity],
  'Unicode:': '👋',
  'Null': null,
  'LastKey': true,
};

Future<BoxImplVm> createTestBox() async {
  var tempDir = await getTempDir();
  var hive = HiveImpl();
  hive.init(tempDir.path);

  var box = await hive.box('testBox');
  await box.putAll(testMap);

  return box;
}

void expectValueEntriesEqual(ValueEntry k1, ValueEntry k2) {
  expect(k1.value, k2.value);
  expect(k1.offset, k2.offset);
  expect(k1.length, k2.length);
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

  group('readKeysFromHiveFile', () {
    Future<BoxImplVm> createBoxFromBytes(Uint8List bytes) async {
      var tempFile = await getTempFile();
      await tempFile.writeAsBytes(bytes, flush: true);

      var mockFile = SyncedFileMock();
      when(mockFile.path).thenReturn(tempFile.path);

      return BoxImplVm(HiveImpl(), 'testBox', BoxOptions(), mockFile);
    }

    test('read keys', () async {
      var registry = TypeRegistryImpl();
      var entries = Map<String, ValueEntry>();

      var bytes = BytesBuilder();
      var deletedLength = 0;
      testMap.forEach((k, v) {
        var frame1 = Frame(k, 1234).toBytes(registry, true, null);
        var frame2 = Frame.tombstone(k).toBytes(registry, true, null);
        var frame3 = Frame(k, 'test').toBytes(registry, true, null);
        var frame4 = Frame(k, v).toBytes(registry, true, null);

        deletedLength += frame1.length + frame2.length + frame3.length;

        bytes.add(frame1);
        bytes.add(frame2);
        bytes.add(frame3);
        entries[k] = ValueEntry(null, bytes.length, frame4.length);
        bytes.add(frame4);
      });

      var box = await createBoxFromBytes(bytes.toBytes());

      expect(box.debugKeys.length, 0);

      await box.initialize();
      for (var key in entries.keys) {
        expectValueEntriesEqual(entries[key], box.debugKeys[key]);
      }
      expect(box.debugTotalBytes, bytes.length);
      expect(box.debugDeletedBytes, deletedLength);

      await box.close();
    });

    test('truncated', () async {
      var bytes = BytesBuilder();
      testMap.forEach((k, v) {
        bytes.add(Frame(k, v).toBytes(TypeRegistryImpl(), true, null));
      });
      var truncated = bytes.toBytes().sublist(0, bytes.length - 1);
      var box = await createBoxFromBytes(truncated);

      await expectLater(
          () => box.initialize(), throwsHiveError('Wrong checksum'));

      await box.close();
    });
  });

  group('get', () {
    test('nonexisting key', () async {
      var box = await createTestBox();

      expect(await box.get('Nothing12345'), null);
      expect(await box.get('AAAAAA'), null);

      expect(await box.get('Nothing12345', defaultValue: 1.0), 1.0);
      expect(await box.get('AAAAAA', defaultValue: [1, 2, 3]), [1, 2, 3]);

      await box.close();
    });

    test('keys in random order', () async {
      var box = await createTestBox();

      for (int i = 0; i < 10; i++) {
        var keys = testMap.keys.toList()..shuffle();
        for (var key in keys) {
          expect(await box.get(key), testMap[key]);
          expect(await box[key], testMap[key]);
        }
      }

      await box.close();
    });
  });

  test('put', () async {
    var mockFile = SyncedFileMock();

    var offset = 0;
    when(mockFile.write(any)).thenAnswer((_) => Future.value(offset));

    var entries = Map<String, ValueEntry>();
    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, entries);

    var deleted = 0;
    for (var key in testMap.keys) {
      var val1 = 1234512345;
      await box.put(key, val1);
      var bytes1 = Frame(key, val1).toBytes(box, true, null);
      verify(mockFile.write(bytes1));

      offset += bytes1.length;

      var val2 = testMap[key];
      await box.put(key, val2);
      var bytes2 = Frame(key, val2).toBytes(box, true, null);
      verify(mockFile.write(bytes2));

      expect(box.debugTotalBytes, offset + bytes2.length);
      expect(box.debugDeletedBytes, deleted + bytes1.length);
      expectValueEntriesEqual(
          entries[key], ValueEntry(null, offset, bytes2.length));

      deleted += bytes1.length;
      offset += bytes2.length;
    }
  });

  test('putAll', () async {
    var mockFile = SyncedFileMock();

    var offset = 20;
    when(mockFile.write(any)).thenAnswer((_) => Future.value(offset));

    var entries = Map<String, ValueEntry>();
    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, entries);

    await box.putAll(testMap);

    var bytes = BytesBuilder();
    var offsets = Map<String, int>();
    testMap.forEach((k, v) {
      var frameBytes = Frame(k, v).toBytes(box, true, null);
      bytes.add(frameBytes);

      offsets[k] = offset;
      offset += frameBytes.length;
    });

    verify(mockFile.write(bytes.toBytes()));
    expect(box.debugTotalBytes, bytes.length);
    for (var key in testMap.keys) {
      expect(entries[key].offset, offsets[key]);
    }
  });

  test('has', () async {
    var mockFile = SyncedFileMock();
    when(mockFile.write(any)).thenAnswer((_) => Future.value(10));
    var box = BoxImplVm(HiveImpl(), 'testBox', BoxOptions(), mockFile);

    expect(box.debugKeys.length, 0);

    for (var key in testMap.keys) {
      expect(await box.has(key), false);
      await box.put(key, testMap[key]);
      expect(await box.has(key), true);
      await box.delete(key);
      expect(await box.has(key), false);
    }
  });

  test('delete', () async {
    var mockFile = SyncedFileMock();
    var entries = {
      'ExistingKey': ValueEntry(null, 111, 20),
      'SecondKey': ValueEntry(null, 200, 40),
    };
    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, entries);

    await box.delete('SomeRandomKey');
    verifyNever(mockFile.setReadPosition(any));
    verifyNever(mockFile.write(any));

    var existingKeyLength = entries['ExistingKey'].length;
    await box.delete('ExistingKey');
    var tombstoneBytes =
        Frame.tombstone('ExistingKey').toBytes(box, true, null);
    verify(mockFile.write(tombstoneBytes));
    expect(entries.containsKey('ExistingKey'), false);
    expect(box.debugTotalBytes, tombstoneBytes.length);
    expect(box.debugDeletedBytes, existingKeyLength + tombstoneBytes.length);
  });

  test('deleteAll', () async {
    var mockFile = SyncedFileMock();

    var offset = 20;
    when(mockFile.write(any)).thenAnswer((_) => Future.value(offset));

    var entries = {
      'ExistingKey': ValueEntry(null, 111, 20),
      'SecondKey': ValueEntry(null, 200, 40),
      'ThirdKey': ValueEntry(null, 250, 40),
    };
    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, entries);

    await box.deleteAll(['SomeRandomKey', 'AnotherOne']);
    verifyNever(mockFile.setReadPosition(any));
    verifyNever(mockFile.write(any));

    var tombstoneBytes = BytesBuilder();
    tombstoneBytes.add(Frame.tombstone('ExistingKey').toBytes(box, true, null));
    tombstoneBytes.add(Frame.tombstone('SecondKey').toBytes(box, true, null));

    await box.deleteAll(['ExistingKey', 'SecondKey']);

    verify(mockFile.write(tombstoneBytes.toBytes()));
    expect(box.debugTotalBytes, tombstoneBytes.length);
    expect(box.debugDeletedBytes, tombstoneBytes.length + 60);
    expect(entries.keys, ['ThirdKey']);
  });

  test('writeFrame', () async {
    var mockFile = SyncedFileMock();
    when(mockFile.write(any)).thenAnswer((_) => Future.value(123));

    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, {});

    var frame = Frame('key', 'value');
    var entry = await box.writeFrame(frame);

    var bytes = frame.toBytes(box, true, null);
    verify(mockFile.write(bytes));

    expect(entry.value, null);
    expect(entry.offset, 123);
    expect(entry.length, bytes.length);
  });

  test('allKeys', () async {
    var mockFile = SyncedFileMock();
    when(mockFile.write(any)).thenAnswer((_) => Future.value(123));

    Map<String, ValueEntry> entries = {
      'key1': ValueEntry(null, 0, 20),
      'SomeKey': ValueEntry(null, 100, 20),
      'ThirdKey': ValueEntry(null, 100, 20),
    };
    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, entries);

    var keys = await box.allKeys();
    expect(keys.length, 3);
    expect(keys.contains('key1'), true);
    expect(keys.contains('SomeKey'), true);
    expect(keys.contains('ThirdKey'), true);
  });

  test('toMap', () async {
    var box = await createTestBox();

    expect(await box.toMap(), testMap);
  });

  test('performCompactationIfNeeded', () async {});

  group('compact', () {
    test('check compactation', () async {
      var boxFile = await getTempFile();
      var comparisonBytes = BytesBuilder();
      var registry = TypeRegistryImpl();

      var syncedFile = SyncedFile(boxFile.path);
      await syncedFile.open();
      var box = BoxImplVm(HiveImpl(), 'testBox', BoxOptions(), syncedFile);

      for (int i = 0; i < 1000; i++) {
        for (var key in testMap.keys) {
          var value = testMap[key];
          await box.put(key, value);
          await box.delete(key);
        }
      }

      for (var key in testMap.keys) {
        await box.put(key, 12345);
        await box.delete(key);
        await box.put(key, 'This is a test');
        await box.put(key, testMap[key]);
        comparisonBytes
            .add(Frame(key, testMap[key]).toBytes(registry, true, null));
      }

      var oldEntries = box.debugKeys;
      await box.compact();

      var offset = 0;
      for (var key in testMap.keys) {
        var newEntry = box.debugKeys[key];
        var oldEntry = oldEntries[key];

        expect(newEntry.offset, offset);
        expect(newEntry.length, oldEntry.length);

        offset += newEntry.length;
      }

      expect(box.debugTotalBytes, offset);
      expect(box.debugDeletedBytes, 0);

      var comparisonBox = await createTestBox();
      var bytes = await File(box.path).readAsBytes();
      expect(bytes, comparisonBytes.toBytes());

      await box.close();
      await comparisonBox.close();
    });

    test('throws error if corrupted', () async {
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
  });

  test('clear', () async {
    var mockFile = SyncedFileMock();
    when(mockFile.write(any)).thenAnswer((_) => Future.value(123));

    Map<String, ValueEntry> entries = {
      'key1': ValueEntry(null, 0, 20),
      'SomeKey': ValueEntry(null, 100, 20),
      'ThirdKey': ValueEntry(null, 100, 20),
    };
    var box = BoxImplVm.debugEntries(
        HiveImpl(), 'testBox', BoxOptions(), mockFile, entries);

    expect(await box.clear(), 3);
    verify(mockFile.truncate(0));
    expect(entries.length, 0);
  });

  test('deleteFromDisk', () async {
    var dir = await getTempDir();
    var hive = HiveImpl();
    hive.init(dir.path);

    var box = await hive.box('testBox');
    await box.put('key', 'value');
    var boxFile = File(box.path);

    expect(await boxFile.exists(), true);
    await box.deleteFromDisk();
    expect(await boxFile.exists(), false);
    expect(hive.isBoxOpen('testBox'), false);
  });
}
