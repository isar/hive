part of hive_flutter;

extension on HiveInterface {
  void simpleInit([String path]) async {
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      var hivePath = appDir.path;
      if (path != null) {
        hivePath = path_helper.join(hivePath, path);
      }
      init(path);
    }
  }
}
