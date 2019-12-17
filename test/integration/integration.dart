import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import '../tests/common.dart';
import '../util/is_browser.dart';

Future<BoxBase> openBox(bool lazy,
    {HiveInterface hive, List<int> encryptionKey}) async {
  hive ??= HiveImpl();
  if (!isBrowser) {
    var dir = await getTempDir();
    hive.init(dir.path);
  }
  var id = Random().nextInt(99999999);
  if (lazy) {
    return await hive.openLazyBox('box$id',
        crashRecovery: false, encryptionKey: encryptionKey);
  } else {
    return await hive.openBox('box$id',
        crashRecovery: false, encryptionKey: encryptionKey);
  }
}

Future<BoxBase> reopenBox(BoxBase box, {List<int> encryptionKey}) async {
  await box.close();
  var hive = (box as BoxBaseImpl).hive;
  if (box is LazyBoxImpl) {
    return await hive.openLazyBox(box.name,
        crashRecovery: false, encryptionKey: encryptionKey);
  } else {
    return await hive.openBox(box.name,
        crashRecovery: false, encryptionKey: encryptionKey);
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

const longTimeout = Timeout(Duration(minutes: 2));
