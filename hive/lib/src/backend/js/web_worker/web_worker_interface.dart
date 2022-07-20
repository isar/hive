import 'dart:async';
import 'dart:html';
import 'dart:js_util';

import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/js/web_worker/web_worker_operation.dart';

class WebWorkerInterface {
  final WebWorkerStackTraceCallback onStackTrace;
  final Worker _worker;
  final Random _random = Random();

  final Map<double, Completer> _queries = {};

  WebWorkerInterface(String href, this.onStackTrace) : _worker = Worker(href) {
    print('[hive] Created Worker($href)');
    _worker.onMessage.listen(_handleMessage);
  }

  Future<T> query<T>(String command, String database,
      [String? objectStore, Object? key, Object? value, String? transaction]) {
    final label = _random.nextDouble();
    final completer = Completer<T>();
    _queries[label] = completer;

    final operation = WebWorkerOperation(
      command: command,
      label: label,
      database: database,
      objectStore: objectStore,
      key: key,
      value: value,
      transaction: transaction,
    );

    _worker.postMessage(jsify(operation.toJson()));
    return completer.future.timeout(Duration(seconds: 45));
  }

  void _handleMessage(MessageEvent event) {
    final label = event.data['label'];
    // don't forget handling errors of our second thread...
    if (label == 'stacktrace') {
      final origin = event.data['origin'];
      final completer = _queries[origin];

      final error = event.data['error']!;

      Future.value(
        onStackTrace.call(event.data['stacktrace'] as String),
      ).then(
        (stackTrace) => completer?.completeError(
          WebWorkerError(error: error, stackTrace: stackTrace),
        ),
      );
    }
    final completer = _queries[label];
    var response = event.data['response'];
    completer?.complete(response);
    _queries.remove(label);
  }
}

class WebWorkerError extends Error {
  /// the error thrown in the web worker. Usually a [String]
  final Object? error;

  /// de-serialized [StackTrace]
  @override
  final StackTrace stackTrace;

  WebWorkerError({required this.error, required this.stackTrace});

  @override
  String toString() {
    return '$error, $stackTrace';
  }
}
