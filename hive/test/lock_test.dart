import 'dart:async';

import 'package:hive/src/util/lock.dart';
import 'package:test/test.dart';

void main() {
  const attempts = 100;
  Completer completer;
  int i;
  Lock lock;

  slowIncrement() async {
    var i0 = i;
    await completer;
    i = i0 + 1;
    return i;
  }

  failSlow() async {
    await completer;
    throw 'failed';
  }

  failFast() {
    throw 'failed';
  }

  fastIncrement() {
    var i0 = i;
    i = i0 + 1;
    return i;
  }

  setUp(() {
    i = 0;
    completer = Completer();
    lock = Lock.newLock();
  });

  test('Without synchronized(), all incrementers run concurrently', () async {
    var futures = List.generate(attempts, (i) => slowIncrement());
    expect(i, equals(0));
    completer.complete();
    await Future.wait(futures);
    expect(i, equals(1));
  });

  test('With synchronized(), all incrementers run sequentially', () async {
    List<Future<int>> futures =
        List.generate(attempts, (i) => lock.synchronized<int>(slowIncrement));
    expect(i, equals(0));
    completer.complete();
    var results = await Future.wait<int>(futures);
    expect(i, equals(attempts));
    expect(results, equals(List.generate(attempts, (i) => i + 1).toList()));
  });

  test('Non-async functions work correctly with synchronized()', () async {
    List<Future<int>> futures =
        List.generate(attempts, (i) => lock.synchronized<int>(fastIncrement));
    var results = await Future.wait<int>(futures);
    expect(i, equals(attempts));
    expect(results, equals(List.generate(attempts, (i) => i + 1).toList()));
  });

  test('Exceptions are propagated', () async {
    expect(i, equals(0));
    final future1 = lock.synchronized(failSlow);
    final future2 = lock.synchronized(slowIncrement);
    final future3 = lock.synchronized(failFast);
    completer.complete();
    expect(future1, throwsA(equals('failed')));
    expect(future2, completion(equals(1)));
    expect(future3, throwsA(equals('failed')));
  });
}
