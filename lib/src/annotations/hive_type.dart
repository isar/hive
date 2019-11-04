part of hive;

/// Annotate classes with [HiveType] to generate a `TypeAdapter`.
class HiveType {
  /// The name of the generated adapter.
  final String adapterName;

  /// If [adapterName] is not set, it'll be `"YourClass" + "Adapter"`.
  const HiveType({this.adapterName});
}
