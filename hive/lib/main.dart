import 'dart:developer';
import 'dart:io';

import 'package:hive/hive.dart';

void main() async {
  Hive.init(Directory.current.path);
  var hive = await Hive.box("testBox");

  var t = Stopwatch()..start();
  for (int i = 0; i < 1000; i++) {
    await hive.put("key$i", "VALUE$i");
  }
  t.stop();
  print(t.elapsedMilliseconds);
  t = Stopwatch()..start();
  for (int i = 0; i < 1000; i++) {
    await hive.get("key$i");
  }
  t.stop();
  print(t.elapsedMilliseconds);
  t = Stopwatch()..start();
  for (int i = 0; i < 1000; i++) {
    await hive.put("key$i", "VALUE$i");
  }
  t.stop();
  print(t.elapsedMilliseconds);
  t = Stopwatch()..start();
  for (int i = 0; i < 1000; i++) {
    await hive.get("key$i");
  }
  t.stop();
  print(t.elapsedMilliseconds);
}
