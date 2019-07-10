part of hive;

abstract class HiveInterface implements TypeRegistry {
  /// The home directory of Hive.
  ///
  /// All box files will be stored in this directory.
  String get path;

  /// Initialize Hive by giving it a home directory.
  void init(String path);

  /// Open a box
  Future<Box> box(
    String name, {
    List<int> encryptionKey,
    bool inMemory = false,
  });

  /// Checks if a specific box is currently open.
  bool isBoxOpen(String name);

  /// Closes all open boxes and then Hive itself.
  Future close({bool compact = false});

  /// Deletes all boxes from disk.
  ///
  /// The home directoy will not be deleted.
  Future deleteFromDisk();

  /// Generates a secure encryption key using the fortuna random algorithm.
  List<int> generateSecureKey();
}
