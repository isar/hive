part of hive_flutter;

/// Flutter extensions for Hive.
extension HiveX on HiveInterface {
  /// Initializes Hive with the path from either
  /// [getApplicationDocumentsDirectory] (default) or
  /// [getApplicationSupportDirectory] ([useSupportDir] = true).
  ///
  /// You can provide a [subDir] where the boxes should be stored. if
  /// [migrateFromDocuments] is set to true, Boxes in (documents dir + subdir)
  /// will be copied over to (support dir + subdir)
  ///
  /// [useSupportDir] cannot be false when [migrateFromDocuments] is true, and
  /// vice versa.
  Future<void> initFlutter({
    bool useSupportDir = false,
    bool migrateFromDocuments = false,
    String? subDir,
  }) async {
    // We don't want the developer to migrate from documents and then try to
    // init Hive with the documents dir.
    assert(useSupportDir == false && migrateFromDocuments == true);

    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) return;

    // Get the directory that Hive uses to stor DB files (dir + subdir).
    final supportDir = useSupportDir
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();

    final appDir = path_helper.join(supportDir.path, subDir);

    if (migrateFromDocuments) {
      // If the app dir doesn't exist, create it. This is usually handled later
      // on in Hive but the directory needs to exist to copy old DB files over.
      if (!await Directory(appDir).exists()) {
        await Directory(appDir).create();
      }

      // Get the old location that Hive used to store files.
      final documentsDir = await getApplicationDocumentsDirectory();
      final oldLocationDir =
          Directory(path_helper.join(documentsDir.path, subDir));

      // If the old location exists, we start looking for old DB files to copy.
      if (await oldLocationDir.exists()) {
        // Make an array to store files to copy.
        final filesToCopy = <File>[];

        await oldLocationDir.list().forEach((event) {
          final extension = path_helper.extension(event.path);

          // If the item is a file and has an extension of .hive, add it and the
          // matching .lock file to the copy array.
          if (event is File && extension == '.hive') {
            filesToCopy.add(File(event.path));

            // We do this instead of just copying all .lock files since .lock
            // can commonly be used for non-Hive purposes.
            filesToCopy
                .add(File('${path_helper.withoutExtension(event.path)}.lock'));
          }
        });

        // Make copy/delete futures for every file and wait for them
        // asynchronously. Files are copied to the new appDir.
        await Future.wait(filesToCopy.map(
          (e) => e
              .copy(path_helper.join(appDir, path_helper.basename(e.path)))
              .then((_) => e.delete()),
        ));
      }
    }

    init(appDir);
  }
}
