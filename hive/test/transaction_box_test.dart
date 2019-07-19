import 'package:hive/src/box/transaction_box.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('TransactionBox', () {
    test('.name', () {
      var box = BoxMock();
      when(box.name).thenReturn('testBoxName');
      var trxBox = TransactionBox(box);
      expect(trxBox.name, 'testBoxName');
    });

    test('.isOpen', () {
      var box = BoxMock();
      when(box.isOpen).thenReturn(true);
      var trxBox = TransactionBox(box);
      expect(trxBox.isOpen, true);
    });

    test('.path', () {
      var box = BoxMock();
      when(box.path).thenReturn('some/box/path');
      var trxBox = TransactionBox(box);
      expect(trxBox.path, 'some/box/path');
    });

    test('.keys', () {
      var box = BoxMock();
      when(box.keys).thenReturn(['key1', 'key2']);
      var entries = <String, dynamic>{'key2': null, 'key3': 'val3'};
      var trxBox = TransactionBox.debug(box, entries);

      expect(trxBox.keys, ['key1', 'key3']);
    });

    test('.watch()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.watch(), throwsUnsupportedError);
    });

    test('.get()', () async {
      var box = BoxMock();
      when(box.get('oldKey')).thenAnswer((i) async => 'oldVal');
      var trxBox = TransactionBox.debug(box, {'newKey': 'newVal'});

      expect(await trxBox.get('newKey'), 'newVal');
      verifyZeroInteractions(box);

      expect(await trxBox.get('oldKey'), 'oldVal');
      verify(box.get('oldKey'));
    });

    test('[]', () {
      var box = BoxMock();
      when(box['oldKey']).thenReturn('oldVal');
      var trxBox = TransactionBox.debug(box, {'newKey': 'newVal'});

      expect(trxBox['newKey'], 'newVal');
      verifyZeroInteractions(box);

      expect(trxBox['oldKey'], 'oldVal');
      verify(box['oldKey']);
    });

    test('has()', () {
      var box = BoxMock();
      when(box.has('oldKey')).thenReturn(true);
      var trxBox = TransactionBox.debug(box, {
        'newKey': 'newVal',
        'deletedKey': null,
      });

      expect(trxBox.has('newKey'), true);
      expect(trxBox.has('deletedKey'), false);
      verifyZeroInteractions(box);

      expect(trxBox.has('oldKey'), true);
      verify(box.has('oldKey'));
    });

    test('.put()', () async {
      var entries = <String, dynamic>{};
      var trxBox = TransactionBox.debug(null, entries);

      await trxBox.put('newKey', 'newVal');
      expect(entries['newKey'], 'newVal');

      await trxBox.put('newKey', null);
      expect(entries['newKey'], null);
    });

    test('.delete()', () async {
      var entries = <String, dynamic>{'key': 'val'};
      var trxBox = TransactionBox.debug(null, entries);

      await trxBox.delete('key');
      expect(entries['key'], null);

      await trxBox.delete('otherKey');
      expect(entries['otherKey'], null);
    });

    test('.putAll()', () async {
      var entries = <String, dynamic>{'key1': 'nothing'};
      var trxBox = TransactionBox.debug(null, entries);

      await trxBox.putAll({'key1': 'val1', 'key2': 1, 'key2': null});
      expect(entries, {'key1': 'val1', 'key2': null});
    });

    test('.deleteAll()', () async {
      var entries = <String, dynamic>{
        'key1': 'val1',
        'key2': 'val2',
        'key3': 'val3'
      };
      var trxBox = TransactionBox.debug(null, entries);

      await trxBox.deleteAll(['key1', 'key3']);
      expect(entries, {'key1': null, 'key2': 'val2', 'key3': null});
    });

    test('.toMap()', () async {
      var box = BoxMock();
      when(box.toMap()).thenAnswer((i) async => {
            'key1': 'val1',
            'key2': 'val2',
            'key3': 'val3',
          });
      var entries = <String, dynamic>{
        'key2': null,
        'key3': 1234,
        'key4': 'val4'
      };
      var trxBox = TransactionBox.debug(box, entries);

      expect(await trxBox.toMap(), {
        'key1': 'val1',
        'key3': 1234,
        'key4': 'val4',
      });
    });

    test('.commit()', () async {
      var box = BoxMock();
      var trxBox = TransactionBox.debug(box, {'key1': 'val1'});
      await trxBox.commit();
      verify(box.putAll({'key1': 'val1'}));
    });

    test('.compact()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.compact(), throwsUnsupportedError);
    });

    test('.clear()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.clear(), throwsUnsupportedError);
    });

    test('.close()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.close(), throwsUnsupportedError);
    });

    test('.deleteFromDisk()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.deleteFromDisk(), throwsUnsupportedError);
    });

    test('.registerAdapter()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.registerAdapter(null, null), throwsUnsupportedError);
    });

    test('.resetAdapters()', () {
      var trxBox = TransactionBox(null);
      expect(() => trxBox.resetAdapters(), throwsUnsupportedError);
    });
  });
}
