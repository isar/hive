part of hive_flutter;

/// Flutter extensions for Hive.
extension HiveX on HiveInterface {
  /// Initializes Hive with the path from [getApplicationDocumentsDirectory].
  ///
  /// You can provide a [subDir] where the boxes should be stored.
  Future initFlutter([String? subDir]) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      var path = appDir.path;
      if (subDir != null) {
        path = path_helper.join(path, subDir);
      }
      init(path);
    }
  }
}
