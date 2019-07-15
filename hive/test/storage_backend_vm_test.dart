@TestOn('vm')

import 'dart:typed_data';

import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/crypto.dart';
import 'package:test/test.dart';

void main() {
  test('primitive crypto', () {
    var crypto = Crypto(Uint8List.fromList(List.filled(32, 1)));
    var bytes = Frame('', 1).toBytes(null, false, crypto);
    var frame = Frame.valueOnlyFromBytes(bytes, null, crypto);
    //expect(frame.value, 1);
  });
}
