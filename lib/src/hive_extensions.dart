part of hive_flutter;

/// Flutter extensions for Hive.
extension HiveX on HiveInterface {
  /// Initializes Hive with the path from [getApplicationDocumentsDirectory].
  ///
  /// You can provide a sub[directory] where the boxes should be stored.
  Future simpleInit([String directory]) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      var path = appDir.path;
      if (directory != null) {
        path = path_helper.join(path, directory);
      }
      init(path);
    }
  }
}
