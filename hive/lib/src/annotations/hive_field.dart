part of hive;

/// Annotate all fields you want to persist with [HiveField].
class HiveField {
  /// The index of this field.
  final int index;

  /// Set `true` to use this enum value as default value instead of null in
  /// null-safety.
  ///
  /// This property currently only used for enum types. In future might be used
  /// for other properties too. If the defaultValue is not provided the first
  /// enum will be used as default value.
  ///
  /// ```dart
  /// @HiveType(typeId: 1)
  /// enum MyEnum {
  ///   @HiveField(0)
  ///   apple,
  ///
  ///   @HiveField(1, defaultValue: true)
  ///   pear
  /// }
  /// ```
  final bool defaultValue;

  const HiveField(this.index, {this.defaultValue = false});
}
