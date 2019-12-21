import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

import '../tests/common.dart';
import '../util/is_browser.dart';

Future<BoxBase<T>> openBox<T>(bool lazy,
    {HiveInterface hive, List<int> encryptionKey}) async {
  hive ??= HiveImpl();
  if (!isBrowser) {
    var dir = await getTempDir();
    hive.init(dir.path);
  }
  var id = Random().nextInt(99999999);
  if (lazy) {
    return await hive.openLazyBox<T>('box$id',
        crashRecovery: false, encryptionKey: encryptionKey);
  } else {
    return await hive.openBox<T>('box$id',
        crashRecovery: false, encryptionKey: encryptionKey);
  }
}

extension BoxBaseX<T> on BoxBase<T> {
  Future<BoxBase<T>> reopen({List<int> encryptionKey}) async {
    await close();
    var hive = (this as BoxBaseImpl).hive;
    if (this is LazyBoxImpl) {
      return await hive.openLazyBox<T>(name,
          crashRecovery: false, encryptionKey: encryptionKey);
    } else {
      return await hive.openBox<T>(name,
          crashRecovery: false, encryptionKey: encryptionKey);
    }
  }

  Future<dynamic> get(dynamic key, {dynamic defaultValue}) {
    if (this is LazyBox) {
      return (this as LazyBox).get(key, defaultValue: defaultValue);
    } else if (this is Box) {
      return Future.value((this as Box).get(key, defaultValue: defaultValue));
    }
    throw ArgumentError('not possible');
  }
}

const longTimeout = Timeout(Duration(minutes: 2));
