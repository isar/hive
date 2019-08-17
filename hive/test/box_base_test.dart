import 'dart:collection';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/box/box_base.dart';
import 'package:hive/src/box/box_options.dart';
import 'package:hive/src/box/change_notifier.dart';
import 'package:hive/src/box/keystore.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

class BoxBaseMock extends BoxBase with Mock {
  BoxBaseMock({
    HiveImpl hive,
    String name,
    StorageBackend backend,
    Keystore keystore,
    ChangeNotifier notifier,
    CompactionStrategy cStrategy,
  }) : super(
          hive ?? HiveImpl(),
          name ?? 'testBox',
          BoxOptions(
            compactionStrategy: cStrategy ?? (total, deleted) => false,
          ),
          backend ?? BackendMock(),
          keystore ?? Keystore(),
          notifier ?? ChangeNotifier(),
        );
}

void main() {
  group('BoxBase', () {
    test('.name', () {
      var box = BoxBaseMock(name: 'testName');
      expect(box.name, 'testName');
    });

    test('.path', () {
      var backend = BackendMock();
      when(backend.path).thenReturn('some/path');
      var box = BoxBaseMock(backend: backend);
      expect(box.path, 'some/path');
    });

    test('.length', () {
      var keystore = Keystore(
        {
          'key1': BoxEntry(null),
          'key2': BoxEntry(null),
        },
      );
      var box = BoxBaseMock(keystore: keystore);
      expect(box.length, 2);
    });

    test('.keys', () {
      var keystore = Keystore({
        'key1': BoxEntry(null),
        'key2': BoxEntry(null),
        'key4': BoxEntry(null)
      });
      var box = BoxBaseMock(keystore: keystore);
      expect(HashSet.from(box.keys), HashSet.from(['key1', 'key2', 'key4']));
    });

    test('.watch()', () {
      var notifier = ChangeNotifierMock();
      var box = BoxBaseMock(notifier: notifier);
      box.watch(key: 123);
      verify(notifier.watch(key: 123));
    });

    test('.keyAt()', () {
      var keystore = Keystore({0: BoxEntry(null), 'test': BoxEntry(null)});
      var box = BoxBaseMock(keystore: keystore);
      expect(box.keyAt(1), 'test');
    });

    test('initialize', () async {
      var backend = BackendMock();
      var box = BoxBaseMock(backend: backend);

      when(backend.initialize(any, any, any)).thenAnswer((i) async {
        i.positionalArguments[0]['key1'] = BoxEntry(1);
        return 2;
      });

      await box.initialize();
      expect(box.deletedEntries, 2);
      expect(box.keystore.toValueMap(), {'key1': 1});
    });

    test('.containsKey()', () {
      var backend = BackendMock();
      var box = BoxBaseMock(
        backend: backend,
        keystore: Keystore({
          'existingKey': BoxEntry(null),
        }),
      );

      expect(box.containsKey('existingKey'), true);
      expect(box.containsKey('nonExistingKey'), false);
      verifyZeroInteractions(backend);
    });

    test('add', () async {
      var keystore = Keystore();
      var box = BoxBaseMock(keystore: keystore);

      keystore.updateAutoIncrement(4);

      expect(await box.add(123), 5);
      verifyInOrder([
        keystore.autoIncrement(),
        box.put(5, 123),
      ]);
    });

    test('addAll', () async {
      var keystore = Keystore();
      var box = BoxBaseMock(keystore: keystore);

      keystore.updateAutoIncrement(4);

      expect(await box.addAll([1, 2, 3]), [5, 6, 7]);
      verifyInOrder([
        keystore.autoIncrement(),
        keystore.autoIncrement(),
        keystore.autoIncrement(),
        box.putAll({5: 1, 6: 2, 7: 3}),
      ]);
    });

    test('putAt', () async {
      var keystore = Keystore({
        'a': BoxEntry(null),
        'b': BoxEntry(null),
        'c': BoxEntry(null),
      });
      var box = BoxBaseMock(keystore: keystore);

      await box.putAt(1, 'test');
      verify(box.put('b', 'test'));
    });

    test('deleteAt', () async {
      var keystore = Keystore({
        'a': BoxEntry(null),
        'b': BoxEntry(null),
        'c': BoxEntry(null),
      });
      var box = BoxBaseMock(keystore: keystore);

      await box.deleteAt(1);
      verify(box.delete('b'));
    });

    test('.clear()', () async {
      var backend = BackendMock();
      var notifier = ChangeNotifierMock();
      var box = BoxBaseMock(
        backend: backend,
        notifier: notifier,
        keystore: Keystore({'key1': BoxEntry(null), 'key2': BoxEntry(null)}),
      );

      expect(await box.clear(), 2);
      //expect(box.debugDeletedEntries, 0);
      verify(backend.clear());
      verify(notifier.notify('key1', null, true));
    });

    group('.compact()', () {
      test('does nothing if there are no deleted entries', () async {
        var backend = BackendMock();
        var box = BoxBaseMock(
          backend: backend,
          keystore: Keystore({
            'key1': BoxEntry(null),
          }),
        );
        await box.compact();
        verifyZeroInteractions(backend);
      });
    });

    test('.close()', () async {
      var hive = HiveMock();
      var notifier = ChangeNotifierMock();
      var backend = BackendMock();
      var box = BoxBaseMock(
        name: 'myBox',
        hive: hive,
        notifier: notifier,
        backend: backend,
      );

      await box.close();
      verifyInOrder([
        notifier.close(),
        hive.unregisterBox('myBox'),
        backend.close(),
      ]);
      expect(box.isOpen, false);
    });

    test('.deleteFromDisk()', () async {
      var hive = HiveMock();
      var notifier = ChangeNotifierMock();
      var backend = BackendMock();
      var box = BoxBaseMock(
        name: 'myBox',
        hive: hive,
        notifier: notifier,
        backend: backend,
      );

      await box.deleteFromDisk();
      verifyInOrder([
        notifier.close(),
        hive.unregisterBox('myBox'),
        backend.deleteFromDisk(),
      ]);
      expect(box.isOpen, false);
    });
  });
}
