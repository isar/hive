import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto_helper.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

export 'generated/frames.g.dart';
export 'generated/frames_body_only.g.dart';
export 'generated/frames_encrypted.g.dart';
export 'generated/frames_encrypted_body_only.g.dart';

TypeRegistry get registry => HiveImpl();

final testFrames = <Frame>[
  const Frame.deleted(0),
  const Frame.deleted(555),
  const Frame(123, null),
  const Frame(0, 'Int key1'),
  const Frame(1, 'Int key2'),
  const Frame(2 ^ 32 - 1, 'Int key3'),
  const Frame.deleted('Tombstone frame'),
  const Frame('Null frame', null),
  const Frame('Int', 123123123),
  const Frame('Large int', 2 ^ 32),
  const Frame('Bool true', true),
  const Frame('Bool false', false),
  const Frame('Float', 12312.991283),
  const Frame('Unicode string',
      'A few characters which are not ASCII: 🇵🇬 😀 🐝 걟 ＄ 乽 👨‍🚀'),
  const Frame('Empty list', []),
  Frame('Byte list', Uint8List.fromList([1, 12, 123, 1234])),
  const Frame('Int list', [123, 456, 129318238]),
  const Frame('Bool list', [true, false, false, true]),
  const Frame('Double list', [
    10.1723812,
    double.infinity,
    double.maxFinite,
    double.minPositive,
    double.negativeInfinity
  ]),
  const Frame('String list', [
    'hello',
    '🧙‍♂️ 👨‍👨‍👧‍👦 ',
    ' ﻬ ﻭ ﻮ ﻯ ﻰ ﻱ',
    'അ ആ ഇ ',
    ' צּ קּ רּ שּ ',
    'ｩ ｪ ｫ ｬ ｭ ｮ ｯ ｰ '
  ]),
  const Frame('List with null', ['This', 'is', 'a', 'test', null]),
  const Frame('List with different types', [
    'List',
    [1, 2, 3],
    5.8,
    true,
    12341234,
    {'t': true, 'f': false},
  ]),
  const Frame('Map', {
    'Bool': true,
    'Int': 1234,
    'Double': 15.7,
    'String': 'Hello',
    'List': [1, 2, null],
    'Null': null,
    'Map': {'Key': 'Val', 'Key2': 2}
  }),
  Frame('DateTime test', [
    DateTime.fromMillisecondsSinceEpoch(0),
    DateTime.fromMillisecondsSinceEpoch(1566656623020),
  ]),
  Frame('BigInt Test', BigInt.parse('1234567890123456789012345678901234567890'))
];

Frame frameWithLength(Frame frame, int length) {
  if (frame.deleted) {
    return Frame.deleted(frame.key, length);
  } else {
    return Frame(frame.key, frame.value, length);
  }
}

Frame frameBodyWithLength(Frame frame, int length) {
  if (frame.deleted) {
    return Frame.deleted(null, length);
  } else {
    return Frame(null, frame.value, length);
  }
}

Frame lazyFrameWithLength(Frame frame, int length) {
  if (frame.deleted) {
    return Frame.deleted(frame.key, length);
  } else {
    return Frame.lazy(frame.key, length);
  }
}

void fEqual(Frame f1, Frame f2) {
  expect(f1.key, f2.key);
  if (f1.value is double && f2.value is double) {
    if (f1.value.isNaN as bool && f1.value.isNaN as bool) return;
  }
  expect(f1.value, f2.value);
  expect(f1.length, f2.length);
  expect(f1.deleted, f2.deleted);
  expect(f1.lazy, f2.lazy);
}

CryptoHelper getDebugCrypto() {
  var secMock = SecureRandomMock();
  when(secMock.nextUint8()).thenReturn(1);
  when(secMock.nextUint16()).thenReturn(2);
  when(secMock.nextUint32()).thenReturn(3);
  when(secMock.nextBytes(any)).thenAnswer((i) =>
      Uint8List.fromList(List.filled(i.positionalArguments[0] as int, 4)));
  return CryptoHelper.debug(Uint8List.fromList(List.filled(32, 1)), secMock);
}

void buildGoldens() async {
  Future<void> generate(String fileName, String varName,
      Uint8List Function(Frame frame) transformer) async {
    var file = File('test/generated/$fileName.g.dart');
    await file.create();
    var code = StringBuffer();
    code.writeln("import 'dart:typed_data';\n");
    code.writeln('final $varName = [');
    for (var frame in testFrames) {
      code.writeln('// ${frame.key}');
      var bytes = transformer(frame);
      code.writeln('Uint8List.fromList(${bytes.toString()}),');
    }
    code.writeln('];');
    file.writeAsStringSync(code.toString(), flush: true);
  }

  await generate('frames', 'frameBytes', (f) {
    return f.toBytes(true, HiveImpl(), null);
  });
  await generate('frames_body_only', 'frameBytesBodyOnly', (f) {
    return f.toBytes(false, HiveImpl(), null);
  });
  await generate('frames_encrypted', 'frameBytesEncrypted', (f) {
    return f.toBytes(true, HiveImpl(), getDebugCrypto());
  });
  await generate('frames_encrypted_body_only', 'frameBytesEncryptedBodyOnly',
      (f) {
    return f.toBytes(false, HiveImpl(), getDebugCrypto());
  });
}
