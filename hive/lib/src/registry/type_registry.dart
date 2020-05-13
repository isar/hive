part of hive;

/// TypeRegistries contain the [TypeAdapter]s associated with a typeId.
///
/// TypeIds have to be unique and must not change.
abstract class TypeRegistry {
  /// Register a [TypeAdapter] to announce it to Hive.
  void registerAdapter<T>(TypeAdapter<T> adapter);
}
