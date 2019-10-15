@TestOn('vm')

import 'dart:async';
import 'dart:io';

import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import '../common.dart';
import '../frames.dart';
import '../storage_backend_vm_test.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var bytes = getFrameBytes(testFrames);
  var frames = testFrames;

  framesSetLengthOffset(frames, frameBytes);

  var dir = await getTempDir();
  var hive = HiveImpl();
  hive.init(dir.path);

  for (var i = 0; i < bytes.length; i++) {
    var subBytes = bytes.sublist(0, i + 1);
    var boxFile = File(path.join(dir.path, 'testBox$i.hive'));
    await boxFile.writeAsBytes(subBytes);

    var box = await hive.openBox('testBox$i', lazy: lazy);

    var subFrames = frames.takeWhile((f) => f.offset + f.length <= i + 1);
    var subKeystore = Keystore.debug(frames: subFrames);
    if (lazy) {
      expect(box.keys, subKeystore.getKeys());
    } else {
      var map = Map.fromIterables(
        subKeystore.getKeys(),
        subKeystore.getValues(),
      );
      expect(box.toMap(), map);
    }

    await box.close();

    expect(await boxFile.readAsBytes(), getFrameBytes(subFrames));
  }
}

Future _performTestWithoutOutput(bool lazy) {
  return runZoned(
    () => _performTest(lazy),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {},
    ),
  );
}

void main() {
  group('test recovery', () {
    test('normal box', () => _performTestWithoutOutput(false));

    test('lazy box', () => _performTestWithoutOutput(true));
  }, timeout: longTimeout);
}
