import 'dart:async';

/// @nodoc
class Isolate {
  /// @nodoc
  static Future<R> run<R>(
    FutureOr<R> Function() computation, {
    String? debugName,
  }) {
    throw UnimplementedError(
      'Isolate.run is not implemented on this platform.',
    );
  }
}
