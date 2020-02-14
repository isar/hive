import 'dart:async';

class ReadWriteSync {
  Future _readTask = Future.value();

  Future _writeTask = Future.value();

  Future<T> syncRead<T>(Future<T> Function() task) {
    var previousTask = _readTask;

    var completer = Completer();
    _readTask = completer.future;

    return previousTask.then((_) => task()).whenComplete(completer.complete);
  }

  Future<T> syncWrite<T>(Future<T> Function() task) {
    var previousTask = _writeTask;

    var completer = Completer();
    _writeTask = completer.future;

    return previousTask.then((_) => task()).whenComplete(completer.complete);
  }

  Future<T> syncReadWrite<T>(FutureOr<T> Function() task) {
    var previousReadTask = _readTask;
    var previousWriteTask = _writeTask;

    var completer = Completer();
    var future = completer.future;
    _readTask = future;
    _writeTask = future;

    return previousReadTask.then((_) {
      return previousWriteTask.then((_) => task());
    }).whenComplete(completer.complete);
  }
}
