import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/backend/vm/storage_backend_vm.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path_helper;

class BackendManager implements BackendManagerInterface {
  @override
  Future<StorageBackend> open(
      String name, String path, bool crashRecovery, CryptoHelper crypto) async {
    if (path == null) {
      throw HiveError('You need to initialize Hive or '
          'provide a path to store the box.');
    }
    var dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    var file = await findHiveFileAndCleanUp(name, path);
    var lockFile = File(path_helper.join(path, '$name.lock'));

    var backend = StorageBackendVm(file, lockFile, crashRecovery, crypto);
    await backend.open();
    return backend;
  }

  @visibleForTesting
  Future<File> findHiveFileAndCleanUp(String name, String path) async {
    var hiveFile = File(path_helper.join(path, '$name.hive'));
    var compactedFile = File(path_helper.join(path, '$name.hivec'));

    if (await hiveFile.exists()) {
      if (await compactedFile.exists()) {
        await compactedFile.delete();
      }
      return hiveFile;
    } else if (await compactedFile.exists()) {
      print('Restoring compacted file.');
      return await compactedFile.rename(hiveFile.path);
    } else {
      await hiveFile.create();
      return hiveFile;
    }
  }

  @override
  Future<void> deleteBox(String name, String path) async {
    await _deleteFileIfExists(File(path_helper.join(path, '$name.hive')));
    await _deleteFileIfExists(File(path_helper.join(path, '$name.hivec')));
    await _deleteFileIfExists(File(path_helper.join(path, '$name.lock')));
  }

  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
