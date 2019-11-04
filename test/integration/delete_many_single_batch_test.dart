import 'package:test/test.dart';

import '../util/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var amount = isBrowser ? 1000 : 20000;
  var box = await openBox(lazy);
  var entries = <String, dynamic>{};
  for (var i = 0; i < amount; i++) {
    entries['string$i'] = 'test';
    entries['int$i'] = -i;
    entries['bool$i'] = i % 2 == 0;
    entries['null$i'] = null;
  }
  await box.putAll(entries);
  await box.put('123123', 'value');

  box = await reopenBox(box);
  await box.deleteAll(entries.keys);

  box = await reopenBox(box);
  for (var i = 0; i < amount; i++) {
    expect(box.containsKey('string$i'), false);
    expect(box.containsKey('int$i'), false);
    expect(box.containsKey('bool$i'), false);
    expect(box.containsKey('null$i'), false);
  }
  expect(await box.get('123123'), 'value');
  await box.close();
}

void main() {
  group('delete many entries in a single batch', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
