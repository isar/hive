part of hive;

class HiveError {
  final String message;

  HiveError(this.message);

  @override
  String toString() {
    return 'HiveError: $message';
  }
}
