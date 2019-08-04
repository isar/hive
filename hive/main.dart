void main() {
  for (var i = 0; i < 1000; i++) {
    t1({'123': 123});
  }
  for (var i = 0; i < 1000; i++) {
    t2('123', 123);
  }
  var s = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    t2('123', 123);
  }
  s.stop();
  print(s.elapsedMicroseconds);
  s
    ..reset()
    ..start();
  for (var i = 0; i < 1000; i++) {
    t1({'123': 123});
  }
  s.stop();
  print(s.elapsedMicroseconds);
}

t1(Map m) {
  m.forEach((k, v) {
    var x = v;
    x += x;
  });
}

t2(String k, dynamic v) {
  var x = v;
  x += x;
}
