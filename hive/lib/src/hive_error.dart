part of hive;

/// An error related to Hive.
class HiveException extends HiveError implements Exception {
  /// A description of the error.
  @override
  final String message;

  HiveException(this.message) : super(message);

  @override
  String toString() {
    return 'HiveException: $message';
  }
}

@Deprecated('Use HiveException instead')
class HiveError extends Error {
  /// A description of the error.
  final String message;

  /// Create a new Hive error (internal)
  HiveError(this.message);

  @override
  String toString() {
    return 'HiveError: $message';
  }
}
