import 'package:test/test.dart';

import '../frames.dart';
import '../util/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var repeat = isBrowser ? 100 : 1000;
  var box = await openBox(lazy);
  for (var i = 0; i < repeat; i++) {
    for (var frame in valueTestFrames) {
      await box.put('${frame.key}n$i', frame.value);
    }
  }

  box = await reopenBox(box);
  for (var i = 0; i < repeat; i++) {
    for (var frame in valueTestFrames) {
      expect(await box.get('${frame.key}n$i'), frame.value);
    }
  }
  await box.close();
}

void main() {
  group('put many entries', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
