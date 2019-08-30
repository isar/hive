part of hive;

/// A event representing a change in a box.
class BoxEvent {
  final dynamic key;
  final dynamic value;
  final bool deleted;

  BoxEvent(this.key, this.value, this.deleted);

  @override
  bool operator ==(dynamic other) {
    if (other is BoxEvent) {
      return other.key == key && other.value == value;
    }
    return false;
  }
}

/// Boxes contain all of your data. In the browser, each box has its own
/// IndexedDB database. On all other platforms, each Box is stored in a
/// seperate file.
///
/// Write operations are asynchronous but change events are sent immeadiately.
/// The new value are immeadiately available. The returned `Future` finishes
/// when the change is written to the backend. If this operation fails, the
/// change are being reverted.
///
/// Read operations for normal boxes are
/// synchronous (the entries are in memory). Lazy boxes have asynchronous read
/// operations.
abstract class Box implements TypeRegistry {
  /// The name of the box. Names are always lowercase.
  String get name;

  /// Whether this box is currently open.
  ///
  /// Most of the operations on a box require it to be open.
  bool get isOpen;

  /// The location of the box in the file system. In the browser, this is null.
  String get path;

  /// Whether this box is lazy or not.
  ///
  /// This is equivalent to `box is LazyBox`.
  bool get lazy;

  /// All the keys in the box.
  ///
  /// The keys are sorted alphabetically in ascending order.
  Iterable<dynamic> get keys;

  /// All the values in the box.
  ///
  /// The values are in the same order as their keys.
  Iterable<dynamic> get values;

  /// The number of entries in the box.
  int get length;

  /// Returns `true` if there are no entries in this box.
  bool get isEmpty;

  /// Returns true if there is at least one entries in this box.
  bool get isNotEmpty;

  /// Get the n-th key in the box.
  dynamic keyAt(int index);

  /// Returns a broadcast stream of change events.
  ///
  /// If the [key] parameter is provided, only events for the specified key are
  /// broadcasted.
  Stream<BoxEvent> watch({dynamic key});

  /// Checks whether the box contains the [key].
  bool containsKey(dynamic key);

  /// Returns the value associated with the given [key]. If the key does not
  /// exist, `null` is returned.
  ///
  /// If [defaultValue] is specified, it is returned in case the key does not
  /// exist.
  dynamic get(dynamic key, {dynamic defaultValue});

  /// Returns the value associated with the n-th key. If there is no such key,
  /// `null` is returned.
  ///
  /// If [defaultValue] is specified, it is returned in case the key does not
  /// exist.
  dynamic getAt(int index, {dynamic defaultValue});

  /// Saves the [key] - [value] pair.
  ///
  /// The key is immeadiately associated with the new value and a change event
  /// is sent instantly. The returned `Future` finishes when the change is
  /// written to the disk.
  /// If this operation fails, the change are being reverted.
  Future<void> put(dynamic key, dynamic value);

  /// Associates the [value] with the n-th key. An exception is raised if the
  /// key does not exist.
  ///
  /// The key is immeadiately associated with the new value and a change event
  /// is sent instantly. The returned `Future` finishes when the change is
  /// written to the disk.
  /// If this operation fails, the change are being reverted.
  Future<void> putAt(int index, dynamic value);

  /// Saves all the key - value pairs in the [entries] map.
  ///
  /// The keys are immeadiately associated with the new values and change events
  /// are sent instantly. The returned `Future` finishes when the changes are
  /// written to the disk.
  /// If this operation fails, the changes are being reverted.
  Future<void> putAll(Map<dynamic, dynamic> entries);

  /// Saves the [value] with an auto-increment key.
  Future<int> add(dynamic value);

  /// Saves the [values] with auto-increment keys.
  Future<List<int>> addAll(List<dynamic> values);

  /// Deletes the given [key] from the box.
  ///
  /// If it does not exist, nothing happens.
  Future<void> delete(dynamic key);

  /// Deletes the n-th key from the box.
  ///
  /// If it does not exist, nothing happens.
  Future<void> deleteAt(int index);

  /// Deletes all the given [keys] from the box.
  ///
  /// If a key does not exist, it is being skipped.
  Future<void> deleteAll(List<dynamic> keys);

  /// Returns a map which contains all key - value pairs of the box.
  Map<dynamic, dynamic> toMap();

  /// Induces compaction manually. This is rarely needed. You should consider
  /// providing a custom compaction strategy instead.
  Future<void> compact();

  /// Removes all entries from the box.
  Future<int> clear();

  /// Closes the box.
  ///
  /// Be careful, this closes all instances of this box. You have to make sure
  /// that you don't access the box anywhere else.
  Future<void> close();

  /// Removes the file which contains the box and closes the box.
  ///
  /// In the browser, the IndexedDB databese is being removed.
  Future<void> deleteFromDisk();
}
