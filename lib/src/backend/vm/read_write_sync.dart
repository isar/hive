import 'dart:async';

class ReadWriteSync {
  Future readTask;

  Future writeTask;

  Future<T> syncRead<T>(Future<T> Function() task) async {
    var previousTask = readTask;
    var completer = Completer.sync();

    readTask = completer.future;
    if (previousTask != null) {
      await previousTask;
    }

    try {
      return await task();
    } finally {
      completer.complete();
    }
  }

  Future<T> syncWrite<T>(Future<T> Function() task) async {
    var previousTask = writeTask;
    var completer = Completer.sync();

    writeTask = completer.future;
    if (previousTask != null) {
      await previousTask;
    }

    try {
      return await task();
    } finally {
      completer.complete();
    }
  }

  Future<T> syncReadWrite<T>(Future<T> Function() task) async {
    var previousReadTask = readTask;
    var completer = Completer.sync();
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

    try {
      return await task();
    } finally {
      completer.complete();
    }
  }
}
