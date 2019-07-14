import 'dart:io';

import 'package:hive/hive.dart';

void main() async {
  Hive.init(Directory.current.path);

  var box = await Hive.box("demoBox");

  await box.put("name", "David");
  await box.put("age", 27);

  print(await box.get("name")); // David
  print(await box.get("age")); // 27

  await box.close();
}
