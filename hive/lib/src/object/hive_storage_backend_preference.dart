part of hive;

/// converts a stringifyed, obfuscated [StackTrace] into a [StackTrace]
typedef WebWorkerStackTraceCallback = FutureOr<StackTrace> Function(
    String obfuscatedStackTrace);

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
  /// the [path] points to the compiled `web_worker.dart.js` file calling
  /// [startWebWorker].
  ///
  /// the [onStackTrace] callback provides a stringifyed [StackTrace] in case
  /// the web worker encounters an error. Together with the source map (the
  /// `.dart.js` file), this can be used to properly capture errors in the web
  /// worker.
  ///
  /// Recommended packages on pub.dev:
  /// - [source_map_stack_trace](https://pub.dev/source_map_stack_trace)
  /// - [source_maps](https://pub.dev/source_maps)
  ///
  /// Default to:
  /// [HiveStorageBackendPreferenceWebWorker.defaultStackTraceHandler]
  factory HiveStorageBackendPreference.webWorker(
    String path, {
    WebWorkerStackTraceCallback onStackTrace =
        HiveStorageBackendPreferenceWebWorker.defaultStackTraceHandler,
  }) =>
      HiveStorageBackendPreferenceWebWorker._(path, onStackTrace: onStackTrace);

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
  /// the default handler for stackTraces in web workers
  static StackTrace defaultStackTraceHandler(String obfuscatedStackTrace) {
    return StackTrace.fromString(obfuscatedStackTrace);
  }

  /// the [String] of the web worker path
  final String path;

  /// a handler converting stringigyed stack traces into a [StackTrace]
  final WebWorkerStackTraceCallback onStackTrace;

  const HiveStorageBackendPreferenceWebWorker._(this.path,
      {required this.onStackTrace})
      : super._();

  @override
  String toString() => 'HiveStorageBackendPreferenceWebWorker( $path )';

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;
}
