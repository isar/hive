part of hive;

class BoxEvent {
  final dynamic key;
  final dynamic value;

  BoxEvent(this.key, this.value);

  bool get deleted => value == null;

  @override
  bool operator ==(dynamic other) {
    if (other is BoxEvent) {
      return other.key == key && other.value == value;
    }
    return false;
  }
}

abstract class Box implements TypeRegistry {
  String get name;

  bool get isOpen;

  /// Returns a path to the `.hive` file of this box. It is not save
  /// to write to this file while the box is open.
  String get path;

  bool get lazy;

  /// Returns a list of all keys in the box.
  ///
  /// This is a very fast operation and doesn't need a disk access.
  Iterable<dynamic> get keys;

  Stream<BoxEvent> watch({dynamic key});

  /// Returns the value associated with the given key.
  ///
  /// The value is loaded from the disk and returned. If the [key] does not
  /// exist, [defaultValue] is returned instead.
  dynamic get(dynamic key, {dynamic defaultValue});

  /// Store a key-value pair in the box.
  ///
  /// Key has to be a non-null String with a maximum length of 255. Value may
  /// be any primitive, [List] or [Map]. Also supported are objects which can
  /// be handled by a registered [TypeAdapter].
  Future<void> put(dynamic key, dynamic value);

  /// Stores multiple key-value pairs in the box.
  ///
  /// This saves disk accesses compared to multiple calls to [put].
  ///
  /// See: [put]
  Future<void> putAll(Map<dynamic, dynamic> entries);

  Future<int> add(dynamic value);

  Future<List<int>> addAll(List<dynamic> values);

  /// Removes a key-value pair from the box if the given [key] exists.
  ///
  /// Returns whether the key existed.
  Future<void> delete(dynamic key);

  /// Deletes all values associated with the given [keys].
  ///
  /// Returns for each key whether it existed.
  Future<void> deleteAll(Iterable<dynamic> keys);

  /// Checks if the box contains the given [key].
  ///
  /// This is a very fast operation and doesn't need a disk access.
  bool containsKey(dynamic key);

  /// Reads all key-value pairs from the box and returns them.
  FutureOr<Map<dynamic, dynamic>> toMap();

  /// Compacts the box. Unused space in the box file is being freed. You don't
  /// have to call this manually. Hive will automatically compact the box if it
  /// is needed.
  Future<void> compact();

  /// Removes all key value pairs
  Future<int> clear();

  /// Closes this box and releases all resources.
  ///
  /// **Important:** All instances of this box are being closed. Make sure you
  /// don't access this box anywhere else.
  Future<void> close();

  /// Closes and deletes this box.
  Future<void> deleteFromDisk();
}
