import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/box_impl.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

BoxImpl getBox({
  String name,
  HiveImpl hive,
  StorageBackend backend,
  ChangeNotifier notifier,
  Keystore keystore,
  CompactionStrategy cStrategy,
}) {
  return BoxImpl(
    hive ?? HiveImpl(),
    name ?? 'testBox',
    BoxOptions(
      compactionStrategy: cStrategy ?? (total, deleted) => false,
    ),
    backend ?? BackendMock(),
    keystore ?? Keystore(),
    notifier,
  );
}

void main() {
  group('BoxImpl', () {
    test('.values', () {
      var keystore = Keystore(
        entries: {
          0: BoxEntry(123),
          'key1': BoxEntry('value1'),
          1: BoxEntry(null),
        },
      );
      var box = getBox(keystore: keystore);

      expect(box.values, [123, null, 'value1']);
    });

    group('.get()', () {
      test('returns defaultValue if key does not exist', () {
        var backend = BackendMock();
        var box = getBox(backend: backend);

        expect(box.get('someKey'), null);
        expect(box.get('otherKey', defaultValue: -12), -12);
        verifyZeroInteractions(backend);
      });

      test('returns cached value if it exists', () {
        var backend = BackendMock();
        var box = getBox(
          backend: backend,
          keystore: Keystore(
            entries: {
              'testKey': BoxEntry('testVal'),
              123: BoxEntry(456),
            },
          ),
        );

        expect(box.get('testKey'), 'testVal');
        expect(box.get(123), 456);
        verifyZeroInteractions(backend);
      });
    });

    test('.getAt()', () {
      var keystore = Keystore(
        entries: {0: BoxEntry('zero'), 'a': BoxEntry('A')},
      );
      var box = getBox(keystore: keystore);

      expect(box.getAt(-1, defaultValue: 123), 123);
      expect(box.getAt(0), 'zero');
      expect(box.getAt(1), 'A');
      expect(box.getAt(2), null);
    });

    group('.put()', () {
      test('value', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(backend.supportsCompaction).thenReturn(true);
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
          cStrategy: (a, b) => true,
        );

        await box.put('key1', 'value1');
        verifyInOrder([
          keystore.beginAddTransaction({'key1': BoxEntry('value1')}),
          notifier.notify('key1', 'value1', false),
          backend.writeFrame(Frame('key1', 'value1'), BoxEntry('value1')),
          keystore.commitTransaction(),
          backend.compact(any),
        ]);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrame(any, any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);
        when(keystore.get(any)).thenReturn(BoxEntry('oldValue'));

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        expect(
            () async => await box.put('key1', 'newValue'), throwsA(anything));
        verifyInOrder([
          keystore.beginAddTransaction({'key1': BoxEntry('newValue')}),
          notifier.notify('key1', 'newValue', false),
          backend.writeFrame(Frame('key1', 'newValue'), BoxEntry('newValue')),
          keystore.cancelTransaction(),
          keystore.get('key1'),
          notifier.notify('key1', 'oldValue', false),
        ]);
      });
    });

    group('.delete()', () {
      test('does nothing when deleting a non existing key', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.delete('testKey');
        await box.delete(123);
        verifyZeroInteractions(backend);
        verifyZeroInteractions(notifier);
      });

      test('delete key', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(backend.supportsCompaction).thenReturn(true);
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
          cStrategy: (a, b) => true,
        );

        await box.delete('key1');
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.beginDeleteTransaction(['key1']),
          notifier.notify('key1', null, true),
          backend.writeFrame(Frame.deleted('key1'), null),
          keystore.commitTransaction(),
          backend.compact(any)
        ]);
      });
    });

    group('.putAll()', () {
      test('values', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(backend.supportsCompaction).thenReturn(true);
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
          cStrategy: (a, b) => true,
        );

        await box.putAll({'key1': 'value1', 'key2': 'value2'});
        verifyInOrder([
          keystore.beginAddTransaction({
            'key1': BoxEntry('value1'),
            'key2': BoxEntry('value2'),
          }),
          notifier.notify('key1', 'value1', false),
          notifier.notify('key2', 'value2', false),
          backend.writeFrames(
            [Frame('key1', 'value1'), Frame('key2', 'value2')],
            [BoxEntry('value1'), BoxEntry('value2')],
          ),
          keystore.commitTransaction(),
          backend.compact(any),
        ]);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrames(any, any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);
        var n = 1;
        when(keystore.get(any)).thenAnswer((i) => BoxEntry('oldValue${n++}'));

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await expectLater(
          () async => await box.putAll({'key1': 'value1', 'key2': 'value2'}),
          throwsA(anything),
        );
        verifyInOrder([
          keystore.beginAddTransaction({
            'key1': BoxEntry('value1'),
            'key2': BoxEntry('value2'),
          }),
          notifier.notify('key1', 'value1', false),
          notifier.notify('key2', 'value2', false),
          backend.writeFrames(
            [Frame('key1', 'value1'), Frame('key2', 'value2')],
            [BoxEntry('value1'), BoxEntry('value2')],
          ),
          keystore.cancelTransaction(),
          keystore.get('key1'),
          notifier.notify('key1', 'oldValue1', false),
          keystore.get('key2'),
          notifier.notify('key2', 'oldValue2', false),
        ]);
      });
    });

    group('.deleteAll()', () {
      test('do nothing when deleting non existing keys', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.deleteAll(['key1', 'key2', 'key3']);
        verifyZeroInteractions(backend);
        verifyZeroInteractions(notifier);
      });

      test('delete keys', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(backend.supportsCompaction).thenReturn(true);
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
          cStrategy: (a, b) => true,
        );

        await box.deleteAll(['key1', 'key2']);
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.containsKey('key2'),
          keystore.beginDeleteTransaction(['key1', 'key2']),
          notifier.notify('key1', null, true),
          notifier.notify('key2', null, true),
          backend.writeFrames(
            [Frame.deleted('key1'), Frame.deleted('key2')],
            null,
          ),
          keystore.commitTransaction(),
          backend.compact(any),
        ]);
      });
    });

    test('.toMap()', () {
      var box = getBox(
        keystore: Keystore(
          entries: {
            'key1': BoxEntry(1, 0, 0),
            'key2': BoxEntry(2, 0, 0),
            'key4': BoxEntry(444, 0, 0),
          },
        ),
      );
      expect(box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
    });
  });
}
