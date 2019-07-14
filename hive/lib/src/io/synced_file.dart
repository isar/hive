import 'dart:async';
import 'dart:io';

import 'package:hive/src/util/lock.dart';
import 'package:meta/meta.dart';

class SyncedFile {
  final String path;
  final Lock _readLock;
  final Lock _writeLock;
  RandomAccessFile _readFile;
  RandomAccessFile _writeFile;
  int _writeOffset = 0;

  int get writeOffset => _writeOffset;

  SyncedFile(this.path)
      : _readLock = Lock.newLock(),
        _writeLock = Lock.newLock();

  @visibleForTesting
  SyncedFile.internal(this.path, this._readFile, this._writeFile,
      this._readLock, this._writeLock);

  Future open() async {
    var file = File(path);

    _readFile = await file.open();
    _writeFile = await file.open(mode: FileMode.append);
    _writeOffset = await _writeFile.length();
  }

  Future setReadPosition(int position) {
    return _readLock.synchronized(() {
      return _readFile.setPosition(position);
    });
  }

  Future<List<int>> read(int bytes) {
    return _readLock.synchronized(() {
      return _readFile.read(bytes);
    });
  }

  Future setWritePosition(int position) {
    if (_writeOffset == position) return Future.value();
    return _writeLock.synchronized(() {
      _writeOffset = position;
      return _writeFile.setPosition(position);
    });
  }

  Future<int> write(List<int> buffer) {
    return _writeLock.synchronized(() async {
      var initialOffset = _writeOffset;
      await _writeFile.writeFrom(buffer);
      _writeOffset += buffer.length;
      return initialOffset;
    });
  }

  Future truncate(int targetLength) {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() async {
        await _writeFile.truncate(targetLength);
        if (_writeOffset > targetLength) {
          await _writeFile.setPosition(targetLength);
          _writeOffset = targetLength;
        }
      });
    });
  }

  Future delete() {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() async {
        await _closeFiles();
        await File(path).delete();
        _readFile = null;
        _writeFile = null;
        _writeOffset = -1;
      });
    });
  }

  Future _closeFiles() async {
    if (_readFile != null) {
      await _readFile.close();
    }
    if (_writeFile != null) {
      await _writeFile.close();
    }
  }

  Future close() {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() {
        return _closeFiles();
      });
    });
  }

  Future<T> syncRead<T>(FutureOr<T> func(SyncedFile file)) {
    return _readLock.synchronized(() {
      var unlocked = SyncedFile.internal(
          path, _readFile, _writeFile, Lock.noLock, _writeLock);
      return func(unlocked);
    });
  }

  Future<T> syncWrite<T>(FutureOr<T> func(SyncedFile file)) {
    return _writeLock.synchronized(() {
      var unlocked = SyncedFile.internal(
          path, _readFile, _writeFile, _readLock, Lock.noLock);
      return func(unlocked);
    });
  }

  Future<T> syncReadWrite<T>(FutureOr<T> func(SyncedFile file)) {
    return _readLock.synchronized(() {
      return _writeLock.synchronized(() {
        var unlocked = SyncedFile.internal(
            path, _readFile, _writeFile, Lock.noLock, Lock.noLock);
        return func(unlocked);
      });
    });
  }
}
