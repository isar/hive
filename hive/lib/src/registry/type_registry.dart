part of hive;

/// TypeRegistries contain the [TypeAdapter]s associated with a typeId.
///
/// TypeIds have to be unique and must not change.
abstract class TypeRegistry {
  /// Register a [TypeAdapter] to announce it to Hive.
  ///
  /// Tries to register [adapter] to registry. If another adapter with same
  /// typeId had been already registered an exception will thrown or the adapter
  /// will be overridden if [override] set to `true`. Please note that internal
  /// adapters are registered and maintained by hive itself. Use [internal]
  /// parameter only if you want to override exists adapter implementation.
  void registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool internal = false,
    bool override = false,
  });

  /// Registers a nested type registry which you can use to register multiple
  /// nested typeId-s using the [configure] function. The nested registry will
  /// be registered as a adapter on the current registry itself with a typeId
  /// provided on the [parentTypeId] argument.
  ///
  /// Check [this PR](https://github.com/hivedb/hive/pull/804) for more details.
  void registerNestedAdapters<T>(
    void Function(TypeRegistry registry) configure, {
    required int parentTypeId,
    bool override = false,
  });

  /// Returns true if a [TypeAdapter] is registered
  bool isAdapterRegistered(int typeId);

  /// Ignore type
  void ignoreTypeId<T>(int typeId);
}
