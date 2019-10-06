import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:test/test.dart';

void main() {
  group('Keystore', () {
    test('.length returns the number of frames in the store', () {
      var keystore = Keystore.debug([Frame('a', 1), Frame(1, 'a')]);
      expect(keystore.length, 2);
      expect(Keystore().length, 0);
    });

    test('.autoIncrement() updates auto increment value', () {
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

    group('.updateAutoIncrement()', () {
      test('increases auto increment value if given key is bigger', () {
        var keystore = Keystore();
        expect(keystore.autoIncrement(), 0);
        keystore.updateAutoIncrement(5);
        expect(keystore.autoIncrement(), 6);
      });

      test('does nothing if given key is lower', () {
        var keystore = Keystore();

        keystore.updateAutoIncrement(20);
        expect(keystore.autoIncrement(), 21);

        keystore.updateAutoIncrement(20);
        expect(keystore.autoIncrement(), 22);
      });
    });

    test('.containsKey() returns whether store has key', () {
      var keystore = Keystore.debug([Frame('key1', null)]);

      expect(keystore.containsKey('key1'), true);
      expect(keystore.containsKey('key2'), false);
    });

    group('.keyAt()', () {
      test('returns the key at the given index', () {
        var keystore = Keystore.debug([
          Frame('key1', null),
          Frame(2, null),
          Frame(0, null),
          Frame('0', null),
        ]);

        expect(keystore.keyAt(0), 0);
        expect(keystore.keyAt(1), 2);
        expect(keystore.keyAt(2), '0');
        expect(keystore.keyAt(3), 'key1');
      });

      test('returns null if the index does not exist', () {
        var keystore = Keystore.debug([Frame('key1', null)]);

        expect(keystore.keyAt(1), null);
        expect(keystore.keyAt(999), null);
        expect(Keystore().keyAt(0), null);
      });
    });

    group('.get()', () {
      test('returns the frame of the given key', () {
        var keystore = Keystore.debug([
          Frame('key1', 'value1'),
          Frame(1, 'value2'),
        ]);

        expect(keystore.get('key1'), Frame('key1', 'value1'));
        expect(keystore.get(1), Frame(1, 'value2'));
      });

      test('returns null if there is no such key', () {
        var keystore = Keystore.debug([Frame('key', 'value')]);
        expect(keystore.get('key2'), null);
        expect(Keystore().get('someKey'), null);
      });
    });

    group('.getAt()', () {
      test('returns the frame at the given index', () {
        var keystore = Keystore.debug([
          Frame('key1', 'value1'),
          Frame(4, 'value2'),
        ]);

        expect(keystore.getAt(0), Frame('key1', 'value1'));
        expect(keystore.getAt(1), Frame(4, 'value2'));
      });

      test('returns null if the index does not exist', () {
        var keystore = Keystore.debug([Frame('key1', 'value1')]);
        expect(keystore.getAt(1), null);
        expect(Keystore().getAt(0), null);
      });
    });

    test('.getKeys() returns the keys in the correct order', () {
      var keystore = Keystore.debug([
        Frame('key1', null),
        Frame(2, null),
        Frame(0, null),
        Frame('0', null),
      ]);

      expect(keystore.getKeys(), [0, 2, '0', 'key1']);
    });

    test('.getValues() returns the values in the order of their keys', () {
      var keystore = Keystore.debug([
        Frame('key1', 4),
        Frame(2, 2),
        Frame(0, null),
        Frame('0', 3),
      ]);

      expect(keystore.getValues(), [null, 2, 3, 4]);
    });

    test('.add()', () {
      var keystore = Keystore();
      keystore.addAll({0: Frame('val1'), 'key2': Frame('val2')});
      expect(keystore.entries, {0: Frame('val1'), 'key2': Frame('val2')});

      keystore.addAll({0: Frame('val3'), 'key3': Frame('val4')});
      expect(keystore.entries,
          {0: Frame('val3'), 'key2': Frame('val2'), 'key3': Frame('val4')});
    });

    test('.delete()', () {
      var keystore = Keystore.debug([
        Frame(0, 'val1'),
        Frame('key2', 'val2'),
        Frame('key3', 'val3'),
      ]);
      expect(keystore.deletedEntries, 0);
      keystore.deleteAll([0, 'key3', 'keyX']);
      expect(keystore.entries, {'key2': Frame('val2')});
      expect(keystore.deletedEntries, 2);
    });

    test('.beginAddTransaction()', () {
      var keystore = Keystore();
      keystore.beginAddTransaction([
        Frame(0, 'val1'),
        Frame('key2', 'val2'),
      ]);

      expect(keystore.frames, [
        Frame(0, 'val1'),
        Frame('key2', 'val2'),
      ]);
      expect(keystore.deletedEntries, 0);
      expect(keystore.transactions.last.added, [0, 'key2']);
      expect(keystore.transactions.last.deleted, {});

      keystore.beginAddTransaction([Frame(0, 'val3')]);

      expect(keystore.frames, [
        Frame(0, 'val3'),
        Frame('key2', 'val2'),
      ]);
      expect(keystore.deletedEntries, 1);
      expect(keystore.transactions.last.added, [0]);
      expect(keystore.transactions.last.deleted, {0: Frame(0, 'val1')});
    });

    test('.beginDeleteTransaction()', () {
      var keystore = Keystore.debug([
        Frame(0, 'val1'),
        Frame('key2', 'val2'),
      ]);
      keystore.beginDeleteTransaction([0, 'key3']);

      expect(keystore.frames, [Frame('key2', 'val2')]);
      expect(keystore.deletedEntries, 1);
      expect(keystore.transactions.last.added, []);
      expect(keystore.transactions.last.deleted, {0: Frame(0, 'val1')});
    });

    test('.commitTransaction()', () {
      var keystore = Keystore.debug([
        Frame(0, 'val1'),
        Frame('key2', 'val2'),
      ]);
      keystore.beginDeleteTransaction([0]);
      keystore.beginDeleteTransaction(['key2']);
      expect(keystore.transactions.first.deleted, {0: Frame(0, 'val1')});
      expect(keystore.transactions.last.deleted, {
        'key2': Frame('key2', 'val2'),
      });

      keystore.commitTransaction();
      expect(keystore.transactions.length, 1);
      expect(keystore.transactions.first.deleted, {
        'key2': Frame('key2', 'val2'),
      });
    });

    test('.cancelTransaction()', () {
      var keystore = Keystore.debug([
        Frame('key1', 'val1'),
        Frame('key2', 'val2'),
      ]);
      keystore.beginAddTransaction([
        Frame('key1', 'val1New'),
        Frame('key3', 'val3'),
      ]);
      keystore.beginDeleteTransaction(['key1', 'key2']);
      keystore.beginAddTransaction([Frame('key1', 'val1New2')]);

      keystore.cancelTransaction();
      expect(keystore.frames, [Frame('key1', 'val1New2')]);

      keystore.cancelTransaction();
      expect(keystore.frames, [
        Frame('key1', 'val1New2'),
        Frame('key2', 'val2'),
      ]);

      keystore.cancelTransaction();
      expect(keystore.frames, [
        Frame('key1', 'val1'),
        Frame('key2', 'val2'),
      ]);
    });

    test('.clear()', () {
      var keystore = Keystore.debug([
        Frame('key1', 'val1'),
        Frame('key2', 'val2'),
      ]);
      keystore.beginDeleteTransaction(['key1']);

      keystore.clear();
      expect(keystore.frames, []);
      expect(keystore.transactions, []);
      expect(keystore.deletedEntries, 0);
    });
  });
}
