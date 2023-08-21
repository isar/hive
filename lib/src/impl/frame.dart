import 'package:isar/isar.dart';

part 'frame.g.dart';

/// @nodoc
@collection
class Frame {
  /// @nodoc
  const Frame({
    required this.id,
    required this.typeId,
    this.key,
    required this.value,
  });

  /// @nodoc
  final int id;

  /// @nodoc
  final int? typeId;

  /// @nodoc
  @Index(unique: true, hash: true)
  final String? key;

  /// @nodoc
  final dynamic value;
}
