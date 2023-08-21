import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:hive/src/impl/frame.dart';
import 'package:isar/isar.dart';
import 'package:test/test.dart';

const _releases = 'https://github.com/isar/isar/releases/download/';

Future<void> initTests() async {
  final lib = switch (Abi.current()) {
    Abi.macosArm64 || Abi.macosX64 => 'libisar_macos.dylib',
    Abi.linuxX64 => 'libisar_linux_x64.so',
    Abi.windowsX64 => 'isar_windows_x64.dll',
    _ => throw UnsupportedError('Unsupported test platform'),
  };

  final libPath = Directory.current.path + Platform.pathSeparator + lib;
  final file = File(libPath);
  if (!file.existsSync()) {
    final uri = Uri.parse('$_releases/${Isar.version}/$lib');
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    await response.pipe(file.openWrite());
  }

  Isar.initialize(file.path);
  Hive.defaultDirectory = Directory.systemTemp.path;
}

Future<Box<E>> openTestBox<E>({String? name}) async {
  await initTests();
  name ??= Random().nextInt(999999).toString();
  final box = Hive.box<E>(name: name);
  box.verify();
  addTearDown(() async {
    if (box.isOpen) {
      box.verify();
      box.deleteFromDisk();
    }
  });

  return box;
}

extension BoxVerify on Box<void> {
  void verify() {
    final isar = Isar.get(schemas: [FrameSchema], name: name);
    final keys =
        isar.frames.where().keyProperty().findAll().whereType<String>();
    expect(keys.length, keys.toSet().length);
  }
}
