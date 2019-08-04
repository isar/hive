import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/lazy_box.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

LazyBox getBox({
  String name,
  HiveImpl hive,
  StorageBackend backend,
  ChangeNotifier notifier,
  Keystore keystore,
  CompactionStrategy cStrategy,
}) {
  return LazyBox(
    hive ?? HiveImpl(),
    name ?? 'testBox',
    BoxOptions(
      lazy: true,
      compactionStrategy: cStrategy ?? (total, deleted) => false,
    ),
    backend ?? BackendMock(),
    keystore ?? Keystore(),
    notifier,
  );
}

void main() {
  group('LazyBox', () {
    group('.get()', () {
      test('returns defaultValue if key does not exist', () async {
        var backend = BackendMock();
        var box = getBox(backend: backend);

        expect(await box.get('someKey'), null);
        expect(await box.get('otherKey', defaultValue: -12), -12);
        verifyZeroInteractions(backend);
      });

      test('reads value from backend', () async {
        var backend = BackendMock();
        when(backend.readValue(any, any, any))
            .thenAnswer((i) async => 'testVal');
        var box = getBox(
          backend: backend,
          keystore: Keystore({'testKey': BoxEntry('testVal', 123, 456)}),
        );

        expect(await box.get('testKey'), 'testVal');
        verify(backend.readValue('testKey', 123, 456));
      });
    });

    test('[] throws exception', () {
      var box = getBox();
      expect(() => box['key'], throwsHiveError('lazy boxes'));
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
          backend.writeFrame(const Frame('key1', 'value1'), BoxEntry(null)),
          keystore.addAll({'key1': BoxEntry(null)}),
          notifier.notify('key1', 'value1'),
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
          backend.writeFrame(const Frame('key1', null), null),
          keystore.addAll({'key1': null}),
          notifier.notify('key1', null),
        ]);
        expect(box.deletedEntries, 1);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrame(any, any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        expect(
            () async => await box.put('key1', 'newValue'), throwsA(anything));
        verifyInOrder([
          keystore.containsKey('key1'),
          backend.writeFrame(const Frame('key1', 'newValue'), BoxEntry(null))
        ]);
        verifyNoMoreInteractions(keystore);
        verifyNoMoreInteractions(notifier);
        expect(box.deletedEntries, 0);
      });
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
          backend.writeFrames(
            [const Frame('key1', 'value1'), const Frame('key2', 'value2')],
            [BoxEntry(null), BoxEntry(null)],
          ),
          keystore.addAll({'key1': BoxEntry(null), 'key2': BoxEntry(null)}),
          notifier.notify('key1', 'value1'),
          notifier.notify('key2', 'value2'),
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
          backend.writeFrames(
            [const Frame('key1', null), const Frame('key2', null)],
            [null, null],
          ),
          keystore.addAll({'key1': null, 'key2': null}),
          notifier.notify('key1', null),
          notifier.notify('key2', null),
        ]);
        expect(box.deletedEntries, 2);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrames(any, any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);

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
          backend.writeFrames(
            [const Frame('key1', 'value1'), const Frame('key2', 'value2')],
            [BoxEntry(null), BoxEntry(null)],
          ),
        ]);
        verifyNoMoreInteractions(keystore);
        verifyNoMoreInteractions(notifier);
        expect(box.deletedEntries, 0);
      });
    });

    test('.toMap()', () async {
      var backend = BackendMock();
      when(backend.readAll())
          .thenAnswer((i) async => {'key1': 1, 'key2': 2, 'key4': 444});
      var box = getBox(
        backend: backend,
        keystore: Keystore({
          'key1': BoxEntry(null, 0, 0),
          'key2': BoxEntry(null, 0, 0),
          'key4': BoxEntry(null, 0, 0),
        }),
      );
      expect(await box.toMap(), {'key1': 1, 'key2': 2, 'key4': 444});
      verify(backend.readAll());
    });
  });
}
