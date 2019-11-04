part of hive;

/// The main API interface of Hive. Available through the `Hive` constant.
abstract class HiveInterface implements TypeRegistry {
  /// The home directory of Hive.
  ///
  /// All box files will be stored in this directory. In the browser, this is
  /// always `null`.
  String get path;

  /// Initialize Hive by giving it a home directory.
  ///
  /// (Not necessary in the browser)
  void init(String path);

  /// Opens a box.
  ///
  /// If the box is already open, the instance is returned and all provided
  /// parameters are being ignored.
  Future<Box<E>> openBox<E>(
    String name, {
    List<int> encryptionKey,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    bool crashRecovery = true,
    bool lazy = false,
  });

  /// Opens an in-memory box from a list of bytes. It does not persist changes.
  ///
  /// This is useful for opening boxes from an asset file.
  Future<Box<E>> openMemoryBox<E>(
    String name, {
    Uint8List bytes,
    List<int> encryptionKey,
    KeyComparator keyComparator,
  });

  /// Returns a previously opened box.
  Box<E> box<E>(String name);

  /// Checks if a specific box is currently open.
  bool isBoxOpen(String name);

  /// Closes all open boxes.
  Future<void> close();

  /// Deletes all currently open boxes from disk.
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
