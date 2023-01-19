part of hive_flutter;

/// Flutter extensions for Hive.
extension HiveX on HiveInterface {
  /// Initializes Hive with the path from [getApplicationDocumentsDirectory].
  ///
  Future<void> initFlutter(
    String? customPath, {
    HiveStorageBackendPreference backendPreference =
        HiveStorageBackendPreference.native,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    String? path;
    if (!kIsWeb) {
      if (customPath != null) {
        path = customPath;
      } else {
        var appDir = await getApplicationDocumentsDirectory();
        path = appDir.path;
      }
    }

    init(
      path,
      backendPreference: backendPreference,
    );
  }
}
