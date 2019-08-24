import 'package:hive/src/box/keystore.dart';
import 'package:test/test.dart';

void main() {
  group('Keystore', () {
    test('.length', () {
      var keystore = Keystore(
        entries: {'a': BoxEntry(1), 1: BoxEntry('a')},
      );
      expect(keystore.length, 2);
      expect(Keystore().length, 0);
    });

    test('autoIncrement', () {
      var keystore = Keystore();
      expect(keystore.autoIncrement(), 0);
      expect(keystore.autoIncrement(), 1);
      expect(keystore.autoIncrement(), 2);

      keystore.updateAutoIncrement(5);
      expect(keystore.autoIncrement(), 6);
      expect(keystore.autoIncrement(), 7);

      keystore.updateAutoIncrement(7);
      expect(keystore.autoIncrement(), 8);
      expect(keystore.autoIncrement(), 9);
    });

    test('.containsKey()', () {
      var keystore = Keystore(entries: {'key1': BoxEntry(null)});

      expect(keystore.containsKey('key1'), true);
      expect(keystore.containsKey('key2'), false);
    });

    test('.keyAt()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry(null),
          2: BoxEntry(null),
          0: BoxEntry(null),
          '0': BoxEntry(null),
        },
      );

      expect(keystore.keyAt(0), 0);
      expect(keystore.keyAt(1), 2);
      expect(keystore.keyAt(2), '0');
      expect(keystore.keyAt(3), 'key1');
    });

    test('.get()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry('value1'),
          1: BoxEntry('value2'),
        },
      );

      expect(keystore.get('key1'), BoxEntry('value1'));
      expect(keystore.get(1), BoxEntry('value2'));
      expect(keystore.get('key2'), null);
    });

    test('.getKeys()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry(null),
          2: BoxEntry(null),
          0: BoxEntry(null),
          '0': BoxEntry(null),
        },
      );

      expect(keystore.getKeys(), [0, 2, '0', 'key1']);
    });

    test('.getValues()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry(4),
          2: BoxEntry(2),
          0: BoxEntry(1),
          '0': BoxEntry(3),
        },
      );

      expect(keystore.getValues(), [1, 2, 3, 4]);
    });

    test('.toValueMap()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry(4),
          2: BoxEntry(2),
          0: BoxEntry(1),
          '0': BoxEntry(3),
        },
      );

      expect(keystore.toValueMap(), {0: 1, 2: 2, '0': 3, 'key1': 4});
    });

    test('.addAll()', () {
      var keystore = Keystore();
      keystore.addAll({0: BoxEntry('val1'), 'key2': BoxEntry('val2')});
      expect(keystore.entries, {0: BoxEntry('val1'), 'key2': BoxEntry('val2')});

      keystore.addAll({0: BoxEntry('val3'), 'key3': BoxEntry('val4')});
      expect(keystore.entries, {
        0: BoxEntry('val3'),
        'key2': BoxEntry('val2'),
        'key3': BoxEntry('val4')
      });
    });

    test('.deleteAll()', () {
      var keystore = Keystore(
        entries: {
          0: BoxEntry('val1'),
          'key2': BoxEntry('val2'),
          'key3': BoxEntry('val3')
        },
      );
      expect(keystore.deletedEntries, 0);
      keystore.deleteAll([0, 'key3', 'keyX']);
      expect(keystore.entries, {'key2': BoxEntry('val2')});
      expect(keystore.deletedEntries, 2);
    });

    test('.beginAddTransaction()', () {
      var keystore = Keystore();
      keystore.beginAddTransaction({
        0: BoxEntry('val1'),
        'key2': BoxEntry('val2'),
      });

      expect(keystore.entries, {0: BoxEntry('val1'), 'key2': BoxEntry('val2')});
      expect(keystore.deletedEntries, 0);
      expect(keystore.transactions.last.added, [0, 'key2']);
      expect(keystore.transactions.last.deleted, {});

      keystore.beginAddTransaction({
        0: BoxEntry('val3'),
      });

      expect(keystore.entries, {0: BoxEntry('val3'), 'key2': BoxEntry('val2')});
      expect(keystore.deletedEntries, 1);
      expect(keystore.transactions.last.added, [0]);
      expect(keystore.transactions.last.deleted, {0: BoxEntry('val1')});
    });

    test('.beginDeleteTransaction()', () {
      var keystore = Keystore(
        entries: {
          0: BoxEntry('val1'),
          'key2': BoxEntry('val2'),
        },
      );
      keystore.beginDeleteTransaction([0, 'key3']);

      expect(keystore.entries, {'key2': BoxEntry('val2')});
      expect(keystore.deletedEntries, 1);
      expect(keystore.transactions.last.added, []);
      expect(keystore.transactions.last.deleted, {0: BoxEntry('val1')});
    });

    test('.commitTransaction()', () {
      var keystore = Keystore(
        entries: {
          0: BoxEntry('val1'),
          'key2': BoxEntry('val2'),
        },
      );
      keystore.beginDeleteTransaction([0]);
      keystore.beginDeleteTransaction(['key2']);
      expect(keystore.transactions.first.deleted, {0: BoxEntry('val1')});
      expect(keystore.transactions.last.deleted, {'key2': BoxEntry('val2')});

      keystore.commitTransaction();
      expect(keystore.transactions.length, 1);
      expect(keystore.transactions.first.deleted, {'key2': BoxEntry('val2')});
    });

    test('.cancelTransaction()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry('val1'),
          'key2': BoxEntry('val2'),
        },
      );
      keystore.beginAddTransaction({
        'key1': BoxEntry('val1New'),
        'key3': BoxEntry('val3'),
      });
      keystore.beginDeleteTransaction(['key1', 'key2']);
      keystore.beginAddTransaction({'key1': BoxEntry('val1New2')});

      keystore.cancelTransaction();
      expect(keystore.entries, {
        'key1': BoxEntry('val1New2'),
      });

      keystore.cancelTransaction();
      expect(keystore.entries, {
        'key1': BoxEntry('val1New2'),
        'key2': BoxEntry('val2'),
      });

      keystore.cancelTransaction();
      expect(keystore.entries, {
        'key1': BoxEntry('val1'),
        'key2': BoxEntry('val2'),
      });
    });

    test('.clear()', () {
      var keystore = Keystore(
        entries: {
          'key1': BoxEntry('val1'),
          'key2': BoxEntry('val2'),
        },
      );
      keystore.beginDeleteTransaction(['key1']);

      keystore.clear();
      expect(keystore.entries, {});
      expect(keystore.transactions, []);
      expect(keystore.deletedEntries, 0);
    });
  });
}
