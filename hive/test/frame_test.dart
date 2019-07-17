import 'dart:io';
import 'dart:typed_data';

import 'package:hive/src/crypto.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'generated/frames.g.dart';
import 'generated/frames_body_only.g.dart';
import 'generated/frames_encrypted.g.dart';
import 'generated/frames_encrypted_body_only.g.dart';

get registry => TypeRegistryImpl();

Frame frameWithLength(Frame frame, int length) {
  return Frame(frame.key, frame.value, length);
}

final testFrames = [
  Frame('Tombstone frame', null),
  Frame('Int', 123123123),
  Frame('Large int', 2 ^ 32),
  Frame('Bool true', true),
  Frame('Bool false', false),
  Frame('Float', 12312.991283),
  Frame('Unicode string',
      'A few characters which are not ASCII: 🇵🇬 😀 🐝 걟 ＄ 乽 👨‍🚀'),
  Frame('Empty list', []),
  Frame('Byte list', Uint8List.fromList([1, 12, 123, 1234])),
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

Crypto getDebugCrypto() {
  var secMock = SecureRandomMock();
  when(secMock.nextUint8()).thenReturn(1);
  when(secMock.nextUint16()).thenReturn(2);
  when(secMock.nextUint32()).thenReturn(3);
  when(secMock.nextBytes(any)).thenAnswer(
      (i) => Uint8List.fromList(List.filled(i.positionalArguments[0], 4)));
  return Crypto.debug(Uint8List.fromList(List.filled(32, 1)), secMock);
}

void fEqual(Frame f1, Frame f2) {
  expect(f1.key, f2.key);
  expect(f1.deleted, f2.deleted);
  if (f1.value is double && f2.value is double) {
    if (f1.value.isNaN && f1.value.isNaN) return;
  }
  expect(f1.value, f2.value);
}

void main() {
  //test('t', buildGoldens);
  group('Frame', () {
    group('.toBytes()', () {
      test('validates key length', () async {
        var tooLongKey = List.filled(256, 'a').join();
        var tooLongFrame = Frame(tooLongKey, 5);
        expect(
          () => tooLongFrame.toBytes(true, registry, null),
          throwsA(anything),
        );

        var validKey = List.filled(255, 'a').join();
        var frame = Frame(validKey, 5);
        frame.toBytes(true, registry, null);
      });

      test('frames', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(true, registry, null);
          expect(bytes, frameBytes[i]);
          i++;
        }
      });

      test('frames body only', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(false, registry, null);
          expect(bytes, frameBytesBodyOnly[i]);
          i++;
        }
      });

      test('encrypted frames', () async {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = await frame.toBytes(true, registry, getDebugCrypto());
          expect(bytes, frameBytesEncrypted[i]);
          i++;
        }
      });

      test('encrypted frames body only', () {
        var i = 0;
        for (var frame in testFrames) {
          var bytes = frame.toBytes(false, registry, getDebugCrypto());
          expect(bytes, frameBytesEncryptedBodyOnly[i]);
          i++;
        }
      });
    });

    group('.fromBytes()', () {
      test('frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var frame = Frame.fromBytes(frameBytes[i], registry, null);
          fEqual(frame, frameWithLength(testFrame, frameBytes[i].length));
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesEncrypted[i];
          var frame = Frame.fromBytes(bytes, registry, getDebugCrypto());
          fEqual(frame, frameWithLength(testFrame, bytes.length));
          i++;
        }
      });
    });

    group('.bodyFromBytes()', () {
      test('frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesBodyOnly[i];
          var frame = Frame.bodyFromBytes(bytes, registry, null);
          fEqual(frame, Frame(null, testFrame.value, bytes.length));
          i++;
        }
      });

      test('encrypted frames', () {
        var i = 0;
        for (var testFrame in testFrames) {
          var bytes = frameBytesEncryptedBodyOnly[i];
          var frame = Frame.bodyFromBytes(bytes, registry, getDebugCrypto());
          fEqual(frame, Frame(null, testFrame.value, bytes.length));
          i++;
        }
      });
    });
  });
}

void buildGoldens() async {
  void generate(String fileName, String varName,
      Uint8List Function(Frame frame) transformer) async {
    var file = File('test/generated/$fileName.g.dart');
    await file.create();
    var code = StringBuffer();
    code.writeln("import 'dart:typed_data';\n");
    code.writeln('final $varName = [');
    for (var frame in testFrames) {
      code.writeln('// ' + frame.key);
      var bytes = transformer(frame);
      code.writeln('Uint8List.fromList(' + bytes.toString() + '),');
    }
    code.writeln('];');
    file.writeAsStringSync(code.toString(), flush: true);
  }

  await generate('frames', 'frameBytes', (f) {
    return f.toBytes(true, registry, null);
  });
  await generate('frames_body_only', 'frameBytesBodyOnly', (f) {
    return f.toBytes(false, registry, null);
  });
  await generate('frames_encrypted', 'frameBytesEncrypted', (f) {
    return f.toBytes(true, registry, getDebugCrypto());
  });
  await generate('frames_encrypted_body_only', 'frameBytesEncryptedBodyOnly',
      (f) {
    return f.toBytes(false, registry, getDebugCrypto());
  });
}
