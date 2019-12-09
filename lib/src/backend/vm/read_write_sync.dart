import 'dart:async';

class ReadWriteSync {
  Future readTask;

  Future writeTask;

  Future<T> syncRead<T>(Future<T> Function() task) async {
    var previousTask = readTask;
    var completer = Completer();

    readTask = completer.future;
    if (previousTask != null) {
      await previousTask;
    }

    var result = await task();
    completer.complete();
    return result;
  }

  Future<T> syncWrite<T>(Future<T> Function() task) async {
    var previousTask = writeTask;
    var completer = Completer();

    writeTask = completer.future;
    if (previousTask != null) {
      await previousTask;
    }

    var result = await task();
    completer.complete();
    return result;
  }

  Future<T> syncReadWrite<T>(Future<T> Function() task) async {
    var previousReadTask = readTask;
    var completer = Completer();
    var future = completer.future;

    readTask = future;
    if (previousReadTask != null) {
      await previousReadTask;
    }

    var previousWriteTask = writeTask;
    writeTask = future;
    if (previousWriteTask != null) {
      await previousWriteTask;
    }

    var result = await task();
    completer.complete();
    return result;
  }
}
