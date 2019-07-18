import 'dart:async';

/// A lock that guards against concurrent executions of synchronized functions.
class Lock {
  Future _last;

  /// Runs [func] sequentially with other functions invoked using
  /// [synchronized] of the same [Lock] instance. The order of execution is
  /// guaranteed to be the same as the order of [synchronized] calls. If an
  /// exception is thrown by [func] during it execution, it gets propagated
  /// to the result of [synchronized].
  Future<T> synchronized<T>(FutureOr<T> func()) async {
    final prev = _last;
    final completer = Completer<void>();
    _last = completer.future;
    if (prev != null) await prev;
    try {
      return await func();
    } finally {
      completer.complete();
    }
  }
}
