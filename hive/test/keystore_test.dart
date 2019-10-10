import 'package:hive/hive.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:test/test.dart';

import 'common.dart';

class _TestHiveObject extends HiveObject {}

void main() {
  void expectTrx(Iterable<KeyTransaction> i1, Iterable<KeyTransaction> i2) {
    expect(i1.length, i2.length);
    var l1 = i1.toList();
    var l2 = i2.toList();
    for (var i = 0; i < i1.length; i++) {
      expect(l1[i].added, l2[i].added);
      expect(l1[i].deleted, l2[i].deleted);
    }
  }

  group('Keystore', () {
    test('.length returns the number of frames in the store', () {
      var keystore = Keystore.debug([Frame('a', 1), Frame(1, 'a')]);
      expect(keystore.length, 2);
      expect(Keystore(null).length, 0);
    });

    test('.autoIncrement() updates auto increment value', () {
      var keystore = Keystore(null);
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
        var keystore = Keystore(null);
        expect(keystore.autoIncrement(), 0);
        keystore.updateAutoIncrement(5);
        expect(keystore.autoIncrement(), 6);
      });

      test('does nothing if given key is lower', () {
        var keystore = Keystore(null);

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
        expect(Keystore(null).keyAt(0), null);
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
        expect(Keystore(null).get('someKey'), null);
      });
    });

    group('.getAt()', () {
      test('returns the frame at the given index', () {
        var keystore = Keystore.debug([
          Frame('key1', 'value1'),
          Frame(4, 'value2'),
        ]);

        expect(keystore.getAt(0), Frame(4, 'value2'));
        expect(keystore.getAt(1), Frame('key1', 'value1'));
      });

      test('returns null if the index does not exist', () {
        var keystore = Keystore.debug([Frame('key1', 'value1')]);
        expect(keystore.getAt(1), null);
        expect(Keystore(null).getAt(0), null);
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

    group('.add()', () {
      test('updates auto increment', () {
        var keystore = Keystore(null);
        expect(keystore.autoIncrement(), 0);

        keystore.add(Frame(123, 'val'));
        expect(keystore.autoIncrement(), 124);

        keystore.add(Frame('500', 'val'));
        expect(keystore.autoIncrement(), 125);
      });

      test('initializes HiveObject', () {
        var box = BoxMock();
        var keystore = Keystore(box);

        var hiveObject = _TestHiveObject();
        keystore.add(Frame('key', hiveObject));

        expect(hiveObject.key, 'key');
        expect(hiveObject.box, box);
      });

      test('adds frame to store', () {
        var keystore = Keystore(null);
        keystore.add(Frame('key2', 'val2'));
        keystore.add(Frame('key1', 'val1'));

        expect(keystore.frames, [Frame('key1', 'val1'), Frame('key2', 'val2')]);
      });

      test('returns overridden Frame', () {
        var keystore = Keystore(null);

        var frame = Frame('key', 'val');
        expect(keystore.add(frame), null);
        expect(keystore.add(Frame('key', 'val2')), frame);
      });

      test('unloads previous HiveObject', () {
        var box = BoxMock();
        var keystore = Keystore(box);

        var hiveObject = HiveObjectMock();
        keystore.add(Frame('key', hiveObject));
        keystore.add(Frame('key', HiveObjectMock()));

        expect(hiveObject.key, null);
        expect(hiveObject.box, null);
      });

      test('increases deletedEntries', () {
        var keystore = Keystore(null);
        expect(keystore.deletedEntries, 0);

        keystore.add(Frame('key1', 'val1'));
        expect(keystore.deletedEntries, 0);

        keystore.add(Frame('key1', 'val2'));
        expect(keystore.deletedEntries, 1);
      });
    });

    group('.delete()', () {
      test('deletes frame from store', () {
        var keystore = Keystore.debug([
          Frame('key2', 'val2'),
          Frame('key1', 'val1'),
        ]);

        keystore.delete('key2');
        expect(keystore.frames, [Frame('key1', 'val1')]);
      });

      test('returns deleted Frame', () {
        var frame = Frame('key', 'val');
        var keystore = Keystore.debug([frame]);

        expect(keystore.delete('key'), frame);
        expect(keystore.delete('key'), null);
      });

      test('unloads deleted HiveObject', () {
        var box = BoxMock();
        var hiveObject = HiveObjectMock();
        var keystore = Keystore.debug([Frame('key', hiveObject)], box);

        keystore.delete('key');
        expect(hiveObject.key, null);
        expect(hiveObject.box, null);
      });

      test('increases deletedEntries', () {
        var keystore = Keystore.debug([Frame('key1', 'val1')]);
        expect(keystore.deletedEntries, 0);

        keystore.delete('key1');
        expect(keystore.deletedEntries, 1);
      });
    });

    group('.beginTransaction()', () {
      test('adding new frames', () {
        var keystore = Keystore(null);
        var created = keystore.beginTransaction([
          Frame('key1', 'val1'),
          Frame('key2', 'val2'),
        ]);

        expect(created, true);
        expect(keystore.transactions.first.added, ['key1', 'key2']);
        expect(keystore.frames, [Frame('key1', 'val1'), Frame('key2', 'val2')]);
      });

      test('overriding existing keys', () {
        var keystore = Keystore.debug([Frame('key1', 'val1')]);
        var created = keystore.beginTransaction([
          Frame('key1', 'val2'),
          Frame('key2', 'val3'),
        ]);

        expect(created, true);
        expect(keystore.transactions.first.deleted, {
          'key1': Frame('key1', 'val1'),
        });
        expect(keystore.frames, [Frame('key1', 'val2'), Frame('key2', 'val3')]);
      });

      test('empty transaction', () {
        var keystore = Keystore.debug([Frame('key1', 'val1')]);
        var created = keystore.beginTransaction([]);

        expect(created, false);
        expect(keystore.frames, [Frame('key1', 'val1')]);
      });

      test('deleting frames', () {
        var keystore = Keystore.debug([
          Frame('key1', 'val1'),
          Frame('key2', 'val2'),
        ]);
        var created = keystore.beginTransaction([
          Frame.deleted('key1'),
          Frame.deleted('key3'),
        ]);

        expect(created, true);
        expect(keystore.transactions.first.deleted, {
          'key1': Frame('key1', 'val1'),
        });
        expect(keystore.frames, [Frame('key2', 'val2')]);
      });
    });

    group('.commitTransaction()', () {
      test('removes the oldest transaction', () {
        var keystore = Keystore(null);
        keystore.beginTransaction([Frame('key1', 'val1')]);
        keystore.beginTransaction([Frame('key2', 'val2')]);

        expectTrx(keystore.transactions, [
          KeyTransaction()..added.add('key1'),
          KeyTransaction()..added.add('key2'),
        ]);

        keystore.commitTransaction();
        expectTrx(keystore.transactions, [KeyTransaction()..added.add('key2')]);
      });

      test('fails if there are no pending transactions', () {
        var keystore = Keystore(null);
        expect(() => keystore.commitTransaction(), throwsStateError);
      });
    });

    group('.cancelTransaction()', () {
      test('add', () {
        var keystore = Keystore(null);
        keystore.beginTransaction([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame('otherKey', 'otherVal')]);

        keystore.cancelTransaction();
        expect(keystore.frames, [Frame('otherKey', 'otherVal')]);
        expectTrx(
            keystore.transactions, [KeyTransaction()..added.add('otherKey')]);
      });

      test('add then override', () {
        var keystore = Keystore(null);
        keystore.beginTransaction([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame('key', 'val2')]);

        keystore.cancelTransaction();
        expect(keystore.frames, [Frame('key', 'val2')]);
        expectTrx(keystore.transactions, [KeyTransaction()..added.add('key')]);
      });

      test('add then delete', () {
        var keystore = Keystore(null);
        keystore.beginTransaction([Frame('key', 'val1')]);
        keystore.beginTransaction([
          Frame('otherKey', 'otherVal'),
          Frame.deleted('key'),
        ]);
        keystore.beginTransaction([
          Frame('key', 'val2'),
        ]);

        keystore.cancelTransaction();
        expect(keystore.frames, [
          Frame('key', 'val2'),
          Frame('otherKey', 'otherVal'),
        ]);
        expectTrx(keystore.transactions, [
          KeyTransaction()..added.add('otherKey'),
          KeyTransaction()..added.add('key'),
        ]);
      });

      test('override', () {
        var keystore = Keystore.debug([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame('key', 'val2')]);

        keystore.cancelTransaction();
        expect(keystore.frames, [Frame('key', 'val1')]);
        expectTrx(keystore.transactions, []);
      });

      test('override then add', () {
        var keystore = Keystore.debug([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame('key', 'val2')]);
        keystore.beginTransaction([Frame('key', 'val3')]);

        keystore.cancelTransaction();
        expect(keystore.frames, [Frame('key', 'val3')]);
        expectTrx(keystore.transactions, [
          KeyTransaction()
            ..added.add('key')
            ..deleted['key'] = Frame('key', 'val1'),
        ]);
      });

      test('override then delete', () {
        var keystore = Keystore.debug([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame('key', 'val2')]);
        keystore.beginTransaction([Frame.deleted('key')]);

        keystore.cancelTransaction();
        expect(keystore.frames, []);
        expectTrx(keystore.transactions, [
          KeyTransaction()..deleted['key'] = Frame('key', 'val1'),
        ]);
      });

      test('delete', () {
        var keystore = Keystore.debug([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame.deleted('key')]);

        keystore.cancelTransaction();
        expect(keystore.frames, [Frame('key', 'val1')]);
        expectTrx(keystore.transactions, []);
      });

      test('delete then add', () {
        var keystore = Keystore.debug([Frame('key', 'val1')]);
        keystore.beginTransaction([Frame.deleted('key')]);
        keystore.beginTransaction([Frame('key', 'val2')]);

        keystore.cancelTransaction();
        expect(keystore.frames, [Frame('key', 'val2')]);
        expectTrx(keystore.transactions, [
          KeyTransaction()
            ..added.add('key')
            ..deleted['key'] = Frame('key', 'val1'),
        ]);
      });
    });

    group('.clear()', () {
      test('clears store', () {
        var keystore = Keystore.debug([
          Frame('key1', 'val1'),
          Frame('key2', 'val2'),
        ]);
        keystore.clear();
        expect(keystore.frames, []);
      });

      test('unloads HiveObjects', () {
        var hiveObject = _TestHiveObject();
        var box = BoxMock();
        var keystore = Keystore.debug([
          Frame('key1', 'val1'),
          Frame('key2', hiveObject),
        ], box);
        expect(hiveObject.key, 'key2');
        expect(hiveObject.box, box);

        keystore.clear();
        expect(hiveObject.key, null);
        expect(hiveObject.box, null);
      });

      test('resets deleted entries', () {
        var keystore = Keystore.debug([
          Frame('key1', 'val1'),
          Frame('key2', 'val2'),
        ]);

        keystore.delete('key1');
        expect(keystore.deletedEntries, 1);

        keystore.clear();
        expect(keystore.deletedEntries, 0);
      });
    });
  });
}
