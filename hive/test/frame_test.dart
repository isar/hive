@TestOn('vm')

import 'dart:typed_data';

import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/io/buffered_file_reader.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:test/test.dart';

import 'common.dart';

get registry => TypeRegistryImpl();

const testFrames = [
  Frame.tombstone('Tombstone frame'),
  Frame('Null frame', null),
  Frame('Int', 123123123),
  Frame('Large int', 2 ^ 32),
  Frame('This is true', true),
  Frame('This is not true', false),
  Frame('Float1', 1232312.9912838261),
  Frame('Float2', double.nan),
  Frame('Unicode string',
      'A few characters which are not ASCII: 🇵🇬 😀 🐝 걟 ＄ 乽 👨‍🚀'),
  Frame('Empty list', []),
  Frame('Int list', [123, 456, 129318238]),
  Frame('Bool list', [true, false, false, true]),
  Frame('Double list', [
    10.1723812,
    double.infinity,
    double.maxFinite,
    double.minPositive,
    double.negativeInfinity
  ]),
  Frame('String list', [
    'hello',
    '🧙‍♂️ 👨‍👨‍👧‍👦 ',
    ' ﻬ ﻭ ﻮ ﻯ ﻰ ﻱ',
    'അ ആ ഇ ',
    ' צּ קּ רּ שּ ',
    'ｩ ｪ ｫ ｬ ｭ ｮ ｯ ｰ '
  ]),
  Frame('List with null', ['This', 'is', 'a', 'test', null]),
  Frame('List with different types', [
    'List',
    [1, 2, 3],
    5.8,
    true,
    12341234,
    {'t': true, 'f': false},
  ]),
  Frame('Map', {
    'Bool': true,
    'Int': 1234,
    'Double': 15.7,
    'String': 'Hello',
    'List': [1, 2, null],
    'Null': null,
    'Map': {'Key': 'Val', 'Key2': 2}
  }),
];

void buildGoldens() async {
  var name = 0;
  for (var frame in testFrames) {
    var file = await getAssetFile('frames', (name++).toString());
    await file.create(recursive: true);
    var frameBytes = frame.toBytes(registry, true, null);
    await file.writeAsBytes(frameBytes);
  }
}

void expectFramesEqual(Frame f1, Frame f2) {
  expect(f1.key, f2.key);
  expect(f1.deleted, f2.deleted);
  if (f1.value is double && f2.value is double) {
    if (f1.value.isNaN && f1.value.isNaN) return;
  }
  expect(f1.value, f2.value);
}

void main() {
  group('toBytes', () {
    test('key length', () async {
      var tooLongKey = List.filled(256, 'a').join();
      var tooLongFrame = Frame(tooLongKey, 5);
      expect(
        () => tooLongFrame.toBytes(registry, true, null),
        throwsA(anything),
      );

      var validKey = List.filled(255, 'a').join();
      var frame = Frame(validKey, 5);
      frame.toBytes(registry, true, null);
    });

    test('golden frames', () async {
      var name = 0;
      for (var frame in testFrames) {
        var file = await getTempAssetFile('frames', '${name++}');
        var bytes = await frame.toBytes(registry, true, null);
        expect(bytes, await file.readAsBytes());
      }
    });
  });

  group('fromReader', () {
    test('golden frames', () async {
      var name = 0;
      for (var goldenFrame in testFrames) {
        var file = await getTempAssetFile('frames', '${name++}');
        var reader = await BufferedFileReader.fromFile(file.path);
        var frame = await Frame.fromBytes(reader.read, registry, true, null);
        expect(frame.length, await file.length());
        expectFramesEqual(frame, goldenFrame);
      }
    });

    test('eof', () async {
      var emptyFile = await getTempFile();
      var reader = await BufferedFileReader.fromFile(emptyFile.path);
      var frame = await Frame.fromBytes(reader.read, registry, true, null);
      expect(frame, null);
    });
  });

  test('encryption / decryption', () async {
    var key = HiveImpl().generateSecureKey();
    var crypto = CryptoHelper(Uint8List.fromList(key));
    for (var frame in testFrames) {
      var bytes = frame.toBytes(registry, true, crypto.encryptor);
      var decryptedFrame = await Frame.fromBytes(
          ByteListReader(bytes).read, registry, true, crypto.decryptor);

      expectFramesEqual(frame, decryptedFrame);
    }
  });
}
