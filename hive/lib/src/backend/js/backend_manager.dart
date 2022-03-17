import 'dart:developer';
import 'dart:js';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';

import 'native/backend_manager.dart' as native;
import 'web_worker/backend_manager.dart' as web_worker;

/// Opens IndexedDB databases
abstract class BackendManager {
  BackendManager._();

  static BackendManagerInterface select(
      [HiveStorageBackendPreference? backendPreference]) {
    switch (backendPreference) {
      case null:
      case HiveStorageBackendPreference.native:
        return native.BackendManager();
      case HiveStorageBackendPreference.webWorker:
        if (_webWorkerSupported) {
          return web_worker.BackendManager();
        } else {
          log('`js:window.Worker` is not present.'
              'Fallback to js-native implementation.');
          return native.BackendManager();
        }
    }
  }

  /// accesses the JS-native `window.Worker`
  ///
  /// ensures `window.Worker` is present
  static bool get _webWorkerSupported => context.hasProperty('Worker');
}
