part of hive;

/// A box contains and manages a collection of key-value pairs.
@pragma('vm:isolate-unsendable')
abstract interface class Box<E> {
  /// Whether this box is currently open.
  ///
  /// Most of the operations on a box require it to be open.
  bool get isOpen;

  /// The name of the box.
  String get name;

  /// The location of the box in the file system. In the browser, this is null.
  String? get directory;

  /// The number of entries in the box.
  int get length;

  /// Whether the box is empty.
  bool get isEmpty;

  /// Whether the box is not empty.
  bool get isNotEmpty;

  /// Start a read transaction on the box.
  ///
  /// Transactions provides and atomic view on the box. All read operations
  /// inside the transaction will see the same state of the box.
  T read<T>(T Function() callback);

  /// Start a write transaction on the box.
  ///
  /// Transactions provides and atomic view on the box. All read operations
  /// inside the transaction will see the same state of the box.
  T write<T>(T Function() callback);

  /// All the keys in the box.
  ///
  /// The keys are sorted by their insertion order.
  List<String> get keys;

  /// Get the n-th key in the box.
  String? keyAt(int index);

  /// Checks whether the box contains the [key].
  bool containsKey(String key);

  // Returns the value associated with the given [key]. If the key does not
  /// exist, `null` is returned.
  ///
  /// If [defaultValue] is specified, it is returned in case the key does not
  /// exist.
  E? get(String key, {E? defaultValue});

  /// Returns the value associated with the n-th key.
  E getAt(int index);

  /// Returns the value associated with the given [key]. The key can either be
  /// a [String] or an [int] to get an entry by its index.
  E? operator [](Object key);

  /// Returns all values associated with the given [keys] or `null` if a key
  /// does not exist.
  List<E?> getAll(Iterable<String> keys);

  /// Returns all values in the given range.
  ///
  /// Throws a [RangeError] if [start] or [end] are out of bounds.
  List<E> getRange(int start, int end);

  /// Returns all values between [startKey] and [endKey] (inclusive).
  List<E> getBetween({String? startKey, String? endKey});

  /// Saves the [key] - [value] pair.
  void put(String key, E value);

  /// Associates the [value] with the n-th key. An exception is raised if the
  /// key does not exist.
  void putAt(int index, E value);

  /// Saves the [key] - [value] pair. The key can either be a [String] or an
  /// [int] to save an entry by its index.
  void operator []=(Object key, E value);

  /// Saves all the key - value pairs in the [entries] map.
  void putAll(Map<String, E> entries);

  /// Overwrites the values in the given range with the given [values].
  void putRange(int start, int end, Iterable<E> values);

  /// Saves the [value] with an auto-increment key.
  void add(E value);

  /// Saves all the [values] with auto-increment keys.
  void addAll(Iterable<E> values);

  /// Deletes the given [key] from the box.
  ///
  /// If it does not exist, nothing happens.
  bool delete(String key);

  /// Deletes the n-th key from the box.
  ///
  /// If it does not exist, nothing happens.
  void deleteAt(int index);

  /// Deletes all the given [keys] from the box.
  ///
  /// If a key does not exist, it is skipped.
  int deleteAll(Iterable<String> keys);

  /// Deletes all the entries in the given range.
  void deleteRange(int start, int end);

  /// Removes all entries from the box.
  void clear({bool notify = true});

  /// Closes the box.
  ///
  /// Be careful, this closes all instances of this box. You have to make sure
  /// that you don't access the box anywhere else after that.
  void close();

  /// Removes the file which contains the box and closes the box.
  ///
  /// If a box is still open in another isolate, it will not be deleted.
  void deleteFromDisk();

  /// Watch for changes to the given [key].
  Stream<E?> watchKey(String key);

  /// Returns a broadcast stream of all changes to the box. This should mainly
  /// be used to be notified of changes in background isolates.
  Stream<void> watch();
}
