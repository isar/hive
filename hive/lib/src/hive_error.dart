part of hive;

class HiveError extends Error {
  final String message;

  HiveError(this.message);

  @override
  String toString() {
    return 'HiveError: $message';
  }
}
