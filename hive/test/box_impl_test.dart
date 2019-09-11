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
      var keystore = Keystore.debug([
        Frame(0, 123),
        Frame('key1', 'value1'),
        Frame(1, null),
      ]);
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
          keystore: Keystore.debug([
            Frame('testKey', 'testVal'),
            Frame(123, 456),
          ]),
        );

        expect(box.get('testKey'), 'testVal');
        expect(box.get(123), 456);
        verifyZeroInteractions(backend);
      });
    });

    test('.getAt()', () {
      var keystore = Keystore.debug([Frame(0, 'zero'), Frame('a', 'A')]);
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
        when(backend.compact(any)).thenAnswer((i) async => []);
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
          cStrategy: (a, b) => true,
        );

        await box.put('key1', 'value1');
        verifyInOrder([
          keystore.beginAddTransaction([Frame('key1', 'value1')]),
          notifier.notify('key1', 'value1', false),
          backend.writeFrame(Frame('key1', 'value1')),
          keystore.commitTransaction(),
          backend.compact(any),
        ]);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrame(any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);
        when(keystore.get(any)).thenReturn(Frame('key1', 'oldValue'));

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        expect(
            () async => await box.put('key1', 'newValue'), throwsA(anything));
        verifyInOrder([
          keystore.beginAddTransaction([Frame('key1', 'newValue')]),
          notifier.notify('key1', 'newValue', false),
          backend.writeFrame(Frame('key1', 'newValue')),
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
        when(backend.compact(any)).thenAnswer((i) async => []);
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
          backend.writeFrame(Frame.deleted('key1')),
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
        when(backend.compact(any)).thenAnswer((i) async => []);
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
          cStrategy: (a, b) => true,
        );

        await box.putAll({'key1': 'value1', 'key2': 'value2'});
        verifyInOrder([
          keystore.beginAddTransaction([
            Frame('key1', 'value1'),
            Frame('key2', 'value2'),
          ]),
          notifier.notify('key1', 'value1', false),
          notifier.notify('key2', 'value2', false),
          backend.writeFrames([
            Frame('key1', 'value1'),
            Frame('key2', 'value2'),
          ]),
          keystore.commitTransaction(),
          backend.compact(any),
        ]);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrames(any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);
        var n = 1;
        when(keystore.get(any))
            .thenAnswer((i) => Frame('key$n', 'oldValue${n++}'));

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
          keystore.beginAddTransaction([
            Frame('key1', 'value1'),
            Frame('key2', 'value2'),
          ]),
          notifier.notify('key1', 'value1', false),
          notifier.notify('key2', 'value2', false),
          backend.writeFrames([
            Frame('key1', 'value1'),
            Frame('key2', 'value2'),
          ]),
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
        when(backend.compact(any)).thenAnswer((i) async => []);
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
          backend.writeFrames([
            Frame.deleted('key1'),
            Frame.deleted('key2'),
          ]),
          keystore.commitTransaction(),
          backend.compact(any),
        ]);
      });
    });

    test('.toMap()', () {
      var box = getBox(
        keystore: Keystore.debug([
          Frame('key1', 1),
          Frame('key2', 2),
          Frame('key4', 444),
        ]),
      );
      expect(box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
    });
  });
}
