part of hive;

/// The API interface of the globally
abstract class HiveInterface implements TypeRegistry {
  /// The home directory of Hive.
  ///
  /// All box files will be stored in this directory.
  String get path;

  /// Initialize Hive by giving it a home directory.
  void init(String path);

  /// Opens a box.
  ///
  /// If the box is already open, the instance is returned and all provided
  /// parameters are being ignored.
  Future<Box> openBox(
    String name, {
    List<int> encryptionKey,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    bool crashRecovery = true,
    bool lazy = false,
  });

  /// Returns a previously opened box.
  Box box(String name);

  /// Checks if a specific box is currently open.
  bool isBoxOpen(String name);

  /// Closes all open boxes and then Hive itself.
  Future<void> close();

  /// Deletes all boxes from disk.
  ///
  /// The home directoy will not be deleted.
  Future<void> deleteFromDisk();

  /// Generates a secure encryption key using the fortuna random algorithm.
  List<int> generateSecureKey();
}

///
typedef KeyComparator = int Function(dynamic key1, dynamic key2);

/// A function which decides when to compact a box.
typedef CompactionStrategy = bool Function(int entries, int deletedEntries);
