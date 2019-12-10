import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import '../tests/common.dart';
import '../util/is_browser.dart';

Future<BoxBase> openBox(bool lazy, [HiveInterface hive]) async {
  hive ??= HiveImpl();
  if (!isBrowser) {
    var dir = await getTempDir();
    hive.init(dir.path);
  }
  var id = Random().nextInt(99999999);
  if (lazy) {
    return await hive.openLazyBox('box$id', crashRecovery: false);
  } else {
    return await hive.openBox('box$id', crashRecovery: false);
  }
}

Future<BoxBase> reopenBox(BoxBase box) async {
  await box.close();
  var hive = (box as BoxBaseImpl).hive;
  if (box is LazyBox) {
    return await hive.openLazyBox(box.name, crashRecovery: false);
  } else {
    return await hive.openBox(box.name, crashRecovery: false);
  }
}

Future<dynamic> getFromBox(BoxBase box, dynamic key, {dynamic defaultValue}) {
  if (box is LazyBox) {
    return box.get(key, defaultValue: defaultValue);
  } else if (box is Box) {
    return Future.value(box.get(key, defaultValue: defaultValue));
  }
  throw ArgumentError('not possible');
}

const longTimeout = Timeout(Duration(minutes: 5));
