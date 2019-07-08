part of hive;

class BoxEvent {
  final String key;
  final dynamic value;
  final bool deleted;

  BoxEvent(this.key, this.value, this.deleted);
}

abstract class Box implements TypeRegistry {
  bool get isOpen;

  Stream<BoxEvent> watch();

  /// Returns the value associated with the given key.
  ///
  /// The value is loaded from the disk and returned. If the [key] does not
  /// exist, [defaultValue] is returned instead.
  Future<T> get<T>(String key, {T defaultValue});

  /// Identical to [get].
  ///
  /// See: [get]
  Future<dynamic> operator [](String key);

  /// Store a key-value pair in the box.
  ///
  /// Key has to be a non-null String with a maximum length of 255. Value may
  /// be any primitive, [List] or [Map]. Also supported are objects which can
  /// be handled by a registered [TypeAdapter].
  Future<void> put(String key, dynamic value);

  /// Stores multiple key-value pairs in the box.
  ///
  /// This saves disk accesses compared to multiple calls to [put].
  ///
  /// See: [put]
  Future<void> putAll(Map<String, dynamic> entries);

  /// Checks if the box contains the given [key].
  ///
  /// This is a very fast operation and doesn't need a disk access.
  Future<bool> has(String key);

  /// Removes a key-value pair from the box if the given [key] exists.
  ///
  /// Returns whether the key existed.
  Future<bool> delete(String key);

  /// Deletes all values associated with the given [keys].
  ///
  /// Returns for each key whether it existed.
  Future<List<bool>> deleteAll(Iterable<String> keys);

  /// Returns a list of all keys in the box.
  ///
  /// This is a very fast operation and doesn't need a disk access.
  Future<Iterable<String>> allKeys();

  /// Reads all key-value pairs from the box and returns them.
  Future<Map<String, dynamic>> toMap();

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
  Future<void> close({bool compact = false});

  /// Returns a [File] pointing to the `.hive` file of this box. It is not save
  /// to write to this file while the box is open.
  File getBoxFile();

  /// Closes and deletes this box.
  Future<void> deleteFromDisk();
}
