part of hive;

class HiveError {
  final String message;

  HiveError(this.message);

  factory HiveError.corrupted(String boxName, String message) {
    return _CorruptedError(boxName, message);
  }

  @override
  String toString() {
    return 'HiveError: $message';
  }
}

class _CorruptedError extends HiveError {
  final String boxName;
  _CorruptedError(this.boxName, String message) : super(message);

  @override
  String toString() {
    return 'HiveError: Hive file of box '$boxName' is corrupted. $message';
  }
}
