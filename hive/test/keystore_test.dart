import 'package:hive/src/box/keystore.dart';
import 'package:test/test.dart';

void main() {
  group('Keystore', () {
    test('.containsKey()', () {
      var keystore = Keystore();
      keystore.addAll({'key1': BoxEntry(null), 'key2': null});

      expect(keystore.containsKey('key1'), true);
      expect(keystore.containsKey('key2'), false);
      expect(keystore.containsKey('key3'), false);

      keystore.keyTransaction({'key3': BoxEntry(4)});

      expect(keystore.containsKey('key1'), true);
      expect(keystore.containsKey('key2'), false);
      expect(keystore.containsKey('key3'), true);

      keystore.keyTransaction({'key1': null});

      expect(keystore.containsKey('key1'), false);
      expect(keystore.containsKey('key2'), false);
      expect(keystore.containsKey('key3'), true);
    });

    test('.get()', () {
      var keystore = Keystore();
      keystore.addAll({'key1': BoxEntry(123), 'key2': null});

      expect(keystore.get('key1'), BoxEntry(123));
      expect(keystore.get('key2'), null);
      expect(keystore.get('key3'), null);

      keystore.keyTransaction({'key3': BoxEntry(456)});

      expect(keystore.get('key1'), BoxEntry(123));
      expect(keystore.get('key2'), null);
      expect(keystore.get('key3'), BoxEntry(456));

      keystore.keyTransaction({'key1': null});

      expect(keystore.get('key1'), null);
      expect(keystore.get('key2'), null);
      expect(keystore.get('key3'), BoxEntry(456));
    });

    test('.getAll()', () {
      var keystore = Keystore();
      keystore.addAll({
        'key1': BoxEntry(123),
        'key2': null,
        'key3': BoxEntry(456),
      });

      //expect(keystore.getAll(), {'key1': BoxEntry(123), 'key3': BoxEntry(456)});

      keystore.keyTransaction({'key2': BoxEntry(222)});

      /*expect(keystore.getAll(), {
        'key1': BoxEntry(123),
        'key2': BoxEntry(222),
        'key3': BoxEntry(456)
      });*/

      keystore.keyTransaction({'key1': null});

      //expect(keystore.getAll(), {'key2': BoxEntry(222), 'key3': BoxEntry(456)});
    });

    test('.addAll()', () {});
  });
}
