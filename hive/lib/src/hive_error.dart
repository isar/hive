part of hive;

// /// An error related to Hive.
// class HiveException extends Error {
//   /// A description of the error.
//   final String message;

//   /// Create a new Hive error (internal)
//   HiveException(this.message);

//   @override
//   String toString() {
//     return 'HiveException: $message';
//   }
// }

/// An error related to Hive.
class HiveException implements Exception {
  final String message;

  HiveException(this.message);

  @override
  String toString() {
    return 'HiveException: $message';
  }

  external StackTrace? get stackTrace;
}
