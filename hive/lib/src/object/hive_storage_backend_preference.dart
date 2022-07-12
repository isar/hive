part of hive;

/// declares the preferred JS StorageBackend to be used
///
/// - [HiveStorageBackendPreference.native] causes almost no startup delay while
/// being slow with huge DB transactions
/// - [HiveStorageBackendPreference.webWorker] has got a small startup delay but
/// is much quicker with huge DB transactions
abstract class HiveStorageBackendPreference {
  // this pretty-much represents an enum with constructor options
  const HiveStorageBackendPreference._();

  /// runs the DB transaction the the main thread
  static const HiveStorageBackendPreference native =
      _HiveStorageBackendPreferenceNative._();

  /// runs the DB in RAM
  ///
  /// Caution: DB will *not* persist
  static const HiveStorageBackendPreference memory =
  _HiveStorageBackendPreferenceMemory._();

  /// uses a web worker for DB transactions
  ///
  /// the path points to the compiled `web_worker.dart.js` file calling
  /// [startWebWorker].
  factory HiveStorageBackendPreference.webWorker(String path) =>
      HiveStorageBackendPreferenceWebWorker._(path);

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}

class _HiveStorageBackendPreferenceNative extends HiveStorageBackendPreference {
  const _HiveStorageBackendPreferenceNative._() : super._();
}

class _HiveStorageBackendPreferenceMemory extends HiveStorageBackendPreference {
  const _HiveStorageBackendPreferenceMemory._() : super._();
}

class HiveStorageBackendPreferenceWebWorker
    extends HiveStorageBackendPreference {
  final String path;

  const HiveStorageBackendPreferenceWebWorker._(this.path) : super._();

  @override
  String toString() => 'HiveStorageBackendPreferenceWebWorker( $path )';

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}
