import 'dart:developer';
import 'dart:io';

import 'package:hive/hive.dart';

var x = false;

Future t() async {
  await t2();
}

Future t2() {
  x = true;
  return Future.value();
}

void a() {
  t();
  print(x);
}

void main() {
  a();
}
