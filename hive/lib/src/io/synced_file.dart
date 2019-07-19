import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/util/lock.dart';
import 'package:meta/meta.dart';

class SyncedFile {
  final String path;
  final Lock readLock;
  final Lock writeLock;
  RandomAccessFile _readFile;
  RandomAccessFile _writeFile;
  int _writeOffset = 0;

  int get writeOffset => _writeOffset;

  SyncedFile(this.path)
      : readLock = Lock(),
        writeLock = Lock();

  @visibleForTesting
  SyncedFile.internal(this.path, this._readFile, this._writeFile, this.readLock,
      this.writeLock);

  Future open() async {
    var file = File(path);

    _readFile = await file.open();
    _writeFile = await file.open(mode: FileMode.append);
    _writeOffset = await _writeFile.length();
  }

  Future<Uint8List> readAt(int position, int bytes) {
    return readLock.synchronized(() async {
      await _readFile.setPosition(position);
      return await _readFile.read(bytes) as Uint8List;
    });
  }

  Future<int> write(List<int> buffer) {
    return writeLock.synchronized(() async {
      var initialOffset = _writeOffset;
      await _writeFile.writeFrom(buffer);
      _writeOffset += buffer.length;
      return initialOffset;
    });
  }

  Future<void> truncate(int targetLength) async {
    return readLock.synchronized(() {
      return writeLock.synchronized(() async {
        await _writeFile.truncate(targetLength);
        if (_writeOffset > targetLength) {
          await _writeFile.setPosition(targetLength);
          _writeOffset = targetLength;
        }
      });
    });
  }

  Future<void> delete() {
    return readLock.synchronized(() {
      return writeLock.synchronized(() async {
        await _closeFiles();
        await File(path).delete();
        _readFile = null;
        _writeFile = null;
        _writeOffset = -1;
      });
    });
  }

  Future<void> _closeFiles() async {
    if (_readFile != null) {
      await _readFile.close();
    }
    if (_writeFile != null) {
      await _writeFile.close();
    }
  }

  Future<void> close() {
    return readLock.synchronized(() {
      return writeLock.synchronized(_closeFiles);
    });
  }
}
