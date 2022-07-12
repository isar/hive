import 'dart:async';
import 'dart:html';
import 'dart:js_util';

import 'dart:math';

import 'package:hive/src/backend/js/web_worker/web_worker_operation.dart';

class WebWorkerInterface {
  final Worker _worker;
  final Random _random = Random();

  final Map<double, Completer> _queries = {};

  WebWorkerInterface(String href) : _worker = Worker(href) {
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
    return completer.future;
  }

  void _handleMessage(MessageEvent event) {
    final label = event.data['label'];
    final completer = _queries[label];
    var response = event.data['response'];
    completer?.complete(response);
    _queries.remove(label);
  }
}
