import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/box/lazy_box_impl.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

LazyBoxImpl getBox({
  String name,
  HiveImpl hive,
  StorageBackend backend,
  ChangeNotifier notifier,
  Keystore keystore,
  CompactionStrategy cStrategy,
}) {
  return LazyBoxImpl(
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
  group('LazyBoxImpl', () {
    test('.values', () {
      var box = getBox();

      expect(() => box.values, throwsUnsupportedError);
    });

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
        when(backend.readValue(any)).thenAnswer((i) async => 'testVal');
        var box = getBox(
          backend: backend,
          keystore: Keystore.debug([
            Frame.lazy('testKey', length: 123, offset: 456),
          ]),
        );

        expect(await box.get('testKey'), 'testVal');
        verify(backend.readValue(
          Frame.lazy('testKey', length: 123, offset: 456),
        ));
      });
    });

    test('.getAt()', () async {
      var keystore = Keystore.debug([
        Frame(0, null),
        Frame('a', null),
      ]);
      var backend = BackendMock();
      when(backend.readValue(Frame('a', null))).thenAnswer((i) async => 'A');
      var box = getBox(keystore: keystore, backend: backend);

      expect(await box.getAt(1), 'A');
      expect(await box.getAt(2), null);
      expect(await box.getAt(3, defaultValue: 123), 123);
    });

    group('.putAll()', () {
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
          backend.writeFrames([
            Frame('key1', 'value1'),
            Frame('key2', 'value2'),
          ]),
          keystore.add(Frame.lazy('key1')),
          keystore.add(Frame.lazy('key2')),
          notifier.notify('key1', 'value1', false),
          notifier.notify('key2', 'value2', false),
        ]);
      });

      test('handles exceptions', () async {
        var backend = BackendMock();
        var keystore = KeystoreMock();
        var notifier = ChangeNotifierMock();

        when(backend.writeFrames(any)).thenThrow('Some error');
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await expectLater(
          () async => await box.putAll(
            {'key1': 'value1', 'key2': 'value2'},
          ),
          throwsA(anything),
        );
        verifyInOrder([
          backend.writeFrames([
            Frame('key1', 'value1'),
            Frame('key2', 'value2'),
          ]),
        ]);
        verifyNoMoreInteractions(keystore);
        verifyNoMoreInteractions(notifier);
      });
    });

    group('.deleteAll()', () {
      test('does nothing when deleting non existing keys', () async {
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
        when(keystore.containsKey(any)).thenReturn(true);

        var box = getBox(
          backend: backend,
          keystore: keystore,
          notifier: notifier,
        );

        await box.deleteAll(['key1', 'key2']);
        verifyInOrder([
          keystore.containsKey('key1'),
          keystore.containsKey('key2'),
          backend.writeFrames([Frame.deleted('key1'), Frame.deleted('key2')]),
          keystore.delete('key1'),
          notifier.notify('key1', null, true),
          keystore.delete(
            'key2',
          ),
          notifier.notify('key2', null, true),
        ]);
      });
    });

    test('.toMap()', () async {
      var box = getBox();
      expect(box.toMap, throwsUnsupportedError);
    });
  });
}
