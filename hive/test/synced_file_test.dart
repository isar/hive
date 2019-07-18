@TestOn('vm')

import 'dart:typed_data';

import 'package:hive/src/io/synced_file.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('SyncedFile', () {
    test('.readAt()', () async {
      var readFile = RAFMock();
      var readLock = LockMock();

      when(readFile.read(5)).thenAnswer((_) async {
        return Uint8List.fromList([1, 2, 3, 4, 5]);
      });

      when(readLock.synchronized(any)).thenAnswer((inv) {
        verifyZeroInteractions(readFile);
        return (inv.positionalArguments[0] as Function)() as Future;
      });

      var syncedFile = SyncedFile.internal('p', readFile, null, readLock, null);
      var result = await syncedFile.readAt(20, 5);
      verifyInOrder([
        readLock.synchronized(any),
        readFile.setPosition(20),
        readFile.read(5),
      ]);
      expect(result, [1, 2, 3, 4, 5]);
    });

    test('.setWritePosition()', () async {
      var writeFile = RAFMock();
      var writeLock = LockMock();

      when(writeLock.synchronized(any)).thenAnswer((inv) {
        verifyNoMoreInteractions(writeFile);
        return (inv.positionalArguments[0] as Function)() as Future;
      });

      var syncedFile =
          SyncedFile.internal('p', null, writeFile, null, writeLock);
      await syncedFile.setWritePosition(25);
      verify(writeLock.synchronized(any));
      verify(writeFile.setPosition(25));
      expect(syncedFile.writeOffset, 25);

      await syncedFile.setWritePosition(25);
      verifyNoMoreInteractions(writeLock);
      verifyNoMoreInteractions(writeFile);
    });

    test('.write()', () async {
      var writeFile = RAFMock();
      var writeLock = LockMock();

      when(writeLock.synchronized(any)).thenAnswer((inv) {
        verifyNoMoreInteractions(writeFile);
        return (inv.positionalArguments[0] as Function)() as Future;
      });

      var syncedFile =
          SyncedFile.internal('p', null, writeFile, null, writeLock);
      await syncedFile.write([1, 2, 3]);
      verify(writeLock.synchronized(any));
      verify(writeFile.writeFrom([1, 2, 3]));
      expect(syncedFile.writeOffset, 3);
    });
  });
}
