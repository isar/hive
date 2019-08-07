import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/cached_box_impl.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

CachedBoxImpl getBox({
  String name,
  HiveImpl hive,
  StorageBackend backend,
  ChangeNotifier notifier,
  Keystore keystore,
  CompactionStrategy cStrategy,
}) {
  return CachedBoxImpl(
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
  group('CachedBoxImpl', () {
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
          keystore: Keystore({
            'testKey': BoxEntry('testVal'),
            123: BoxEntry(456),
          }),
        );

        reset(backend);
        expect(box.get('testKey'), 'testVal');
        expect(box.get(123), 456);
        verifyZeroInteractions(backend);
      });
    });

    test('[]', () {
      var box = getBox(
        keystore: Keystore({'key': BoxEntry('value'), 123: BoxEntry(456)}),
      );
      expect(box['key'], 'value');
      expect(box['nonexistantKey'], null);
      expect(box[123], 456);
      expect(box[999], null);
    });

    group('.put()', () {
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

        await box.put('testKey', null);
        await box.put(123, null);
        verifyZeroInteractions(backend);
        verifyZeroInteractions(notifier);
        expect(box.deletedEntries, 0);
      });

      test('value', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.put('key1', 'value1');
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.keyTransaction({'key1': BoxEntry('value1')}),
          notifier.notify('key1', 'value1'),
          backend.writeFrame(const Frame('key1', 'value1'), BoxEntry('value1')),
          keystore.commitKeyTransaction(),
        ]);
        expect(box.deletedEntries, 0);
      });

      test('delete key', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.put('key1', null);
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.keyTransaction({'key1': null}),
          notifier.notify('key1', null),
          backend.writeFrame(const Frame('key1', null), null),
          keystore.commitKeyTransaction(),
        ]);
        expect(box.deletedEntries, 1);
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
          keystore.containsKey('key1'),
          keystore.keyTransaction({'key1': BoxEntry('newValue')}),
          notifier.notify('key1', 'newValue'),
          backend.writeFrame(
              const Frame('key1', 'newValue'), BoxEntry('newValue')),
          keystore.cancelKeyTransaction(),
          keystore.get('key1'),
          notifier.notify('key1', 'oldValue'),
        ]);
        expect(box.deletedEntries, 0);
      });
    });

    test('[]=', () {
      var box = getBox(keystore: Keystore());

      box['key'] = 'value';
      expect(box['key'], 'value');

      box['key'] = null;
      expect(box.containsKey('key'), false);
    });

    group('.putAll()', () {
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

        await box.putAll({'key1': null, 'key2': null, 'key3': null});
        verifyZeroInteractions(backend);
        verifyZeroInteractions(notifier);
        expect(box.deletedEntries, 0);
      });

      test('values', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(keystore.containsKey(any)).thenReturn(false);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.putAll({'key1': 'value1', 'key2': 'value2'});
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.containsKey('key2'),
          keystore.keyTransaction({
            'key1': BoxEntry('value1'),
            'key2': BoxEntry('value2'),
          }),
          notifier.notify('key1', 'value1'),
          notifier.notify('key2', 'value2'),
          backend.writeFrames(
            [const Frame('key1', 'value1'), const Frame('key2', 'value2')],
            [BoxEntry('value1'), BoxEntry('value2')],
          ),
          keystore.commitKeyTransaction(),
        ]);
        expect(box.deletedEntries, 0);
      });

      test('delete keys', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.putAll({'key1': null, 'key2': null});
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.containsKey('key2'),
          keystore.keyTransaction({'key1': null, 'key2': null}),
          notifier.notify('key1', null),
          notifier.notify('key2', null),
          backend.writeFrames(
            [const Frame('key1', null), const Frame('key2', null)],
            [null, null],
          ),
          keystore.commitKeyTransaction(),
        ]);
        expect(box.deletedEntries, 2);
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
          keystore.containsKey('key1'),
          keystore.containsKey('key2'),
          keystore.keyTransaction({
            'key1': BoxEntry('value1'),
            'key2': BoxEntry('value2'),
          }),
          notifier.notify('key1', 'value1'),
          notifier.notify('key2', 'value2'),
          backend.writeFrames(
            [const Frame('key1', 'value1'), const Frame('key2', 'value2')],
            [BoxEntry('value1'), BoxEntry('value2')],
          ),
          keystore.cancelKeyTransaction(),
          keystore.get('key1'),
          notifier.notify('key1', 'oldValue1'),
          keystore.get('key2'),
          notifier.notify('key2', 'oldValue2'),
        ]);
        expect(box.deletedEntries, 0);
      });
    });

    test('.toMap()', () {
      var box = getBox(
        keystore: Keystore({
          'key1': BoxEntry(1, 0, 0),
          'key2': BoxEntry(2, 0, 0),
          'key4': BoxEntry(444, 0, 0),
        }),
      );
      expect(box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
    });
  });
}
