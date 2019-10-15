import 'package:test/test.dart';

import '../util/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var amount = isBrowser ? 5 : 100;
  var box = await openBox(lazy);
  for (var i = 0; i < amount; i++) {
    for (var n = 0; n < 100; n++) {
      await box.put('string$i', 'test$n');
      await box.put('int$i', n);
      await box.put('bool$i', n % 2 == 0);
      await box.put('null$i', null);
    }
  }

  box = await reopenBox(box);
  for (var i = 0; i < amount; i++) {
    expect(await box.get('string$i'), 'test99');
    expect(await box.get('int$i'), 99);
    expect(await box.get('bool$i'), false);
    expect(await box.get('null$i', defaultValue: 0), null);
  }
  await box.close();
}

void main() {
  group('put many entries with the same key', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
