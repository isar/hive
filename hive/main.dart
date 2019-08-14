import 'dart:collection';

void main() {
  var hm2 = SplayTreeMap((a, b) {
    if (a is int) {
      if (b is int) {
        return a.compareTo(b);
      } else {
        return -1;
      }
    } else if (a is String) {
      if (b is String) {
        return a.compareTo(b);
      } else {
        return 1;
      }
    }
  });
  t(hm2);
  r(hm2);

  hm2 = SplayTreeMap((dynamic a, dynamic b) {
    if (a is int) {
      if (b is int) {
        return a.compareTo(b);
      } else {
        return -1;
      }
    } else {
      if (b is String) {
        return (a as String).compareTo(b);
      } else {
        return 1;
      }
    }
  });
  t(hm2);
  var s2 = Stopwatch()..start();
  r(hm2);
  s2.stop();
  print(s2.elapsedMicroseconds);

  var hm = HashMap();
  t(hm);
  r(hm);

  hm = HashMap();
  t(hm);
  var s = Stopwatch()..start();
  r(hm);
  s.stop();
  print(s.elapsedMicroseconds);
}

void t(Map hm) {
  for (var i = 0; i < 1000; i++) {
    hm[i] = 12345;
  }
  for (var i = 0; i < 1000; i++) {
    hm['$i'] = 12345;
  }
}

void r(Map hm) {
  for (int i = 0; i < 10; i++) hm.values.toList();
  /*for (var i = 0; i < 1000; i++) {
    var x = hm[i];
  }
  for (var i = 0; i < 1000; i++) {
    var x = hm['$i'];
  }*/
}
