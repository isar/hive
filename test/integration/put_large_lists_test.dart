import 'dart:typed_data';

import 'package:test/test.dart';

import 'integration.dart';

Future _performTest(bool lazy) async {
  var box = await openBox(lazy);

  var stringList = List.filled(1000000, 'test', growable: true)..add(null);
  var doubleList = List.filled(1000000, 1.212312);
  var byteList = Uint8List.fromList(List.filled(1000000, 123));

  for (var i = 0; i < 5; i++) {
    await box.put('stringList$i', stringList);
    await box.put('doubleList$i', doubleList);
    await box.put('byteList$i', byteList);
  }

  box = await reopenBox(box);
  for (var i = 0; i < 5; i++) {
    var readStringList = await getFromBox(box, 'stringList$i');
    var readDoubleList = await getFromBox(box, 'doubleList$i');
    var readByteList = await getFromBox(box, 'byteList$i');

    expect(readStringList, stringList);
    expect(readDoubleList, doubleList);
    expect(readByteList, byteList);
  }
  await box.close();
}

void main() {
  group('put large lists', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
