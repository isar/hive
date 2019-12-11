part of hive;

/// Annotate fields with [HiveLink] to link them to other [HiveObject]s.
class HiveLink {
  /// The box that contains the other [HiveObject].
  final String boxName;

  const HiveLink(this.boxName);
}
