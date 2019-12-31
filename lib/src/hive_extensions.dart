part of hive_flutter;

extension HiveX on HiveInterface {
  Future simpleInit([String path]) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      var hivePath = appDir.path;
      if (path != null) {
        hivePath = path_helper.join(hivePath, path);
      }
      init(hivePath);
    }
  }
}
