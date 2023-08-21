import 'dart:io';

import 'package:test/test.dart';

import 'common.dart';

void main() {
  group('Box', () {
    test('.isOpen', () async {
      final box = await openTestBox<dynamic>();
      expect(box.isOpen, true);
      box.deleteFromDisk();
      expect(box.isOpen, false);
    });

    test('.name', () async {
      final box = await openTestBox<dynamic>(name: 'testBox');
      expect(box.name, 'testBox');
    });

    test('.directory', () async {
      final box = await openTestBox<dynamic>();
      expect(box.directory, Directory.systemTemp.path);
    });

    test('.length', () async {
      final box = await openTestBox<dynamic>();
      expect(box.length, 0);
      box.put('key1', 'hello');
      expect(box.length, 1);
      box.put('key2', 'world');
      expect(box.length, 2);
      box.delete('key1');
      expect(box.length, 1);
      box.delete('key2');
      expect(box.length, 0);
    });

    group('.keys', () {
      test('empty', () async {
        final box = await openTestBox<dynamic>();
        expect(box.keys, isEmpty);
      });

      test('contains all String only keys', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key1', 'hello2');
        expect(box.keys, ['key2', 'key1']);
      });

      test('contains no int keys', () async {
        final box = await openTestBox<dynamic>();
        box.add('hello');
        box.add('world');
        box.add('hello2');
        expect(box.keys, isEmpty);
      });

      test('contains only String keys if there are both', () async {
        final box = await openTestBox<dynamic>();
        box.put('key2', 'hello');
        box.add('world');
        box.put('key2', 'hello2');
        expect(box.keys, ['key2']);
      });
    });

    group('.keyAt()', () {
      test('throws IndexError for non-existing index', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.keyAt(0), throwsA(isA<IndexError>()));
      });

      test('returns null if key is not set', () async {
        final box = await openTestBox<dynamic>();
        box.put('key2', 'hello');
        box.add('world');
        expect(box.keyAt(1), null);
      });

      test('returns key', () async {
        final box = await openTestBox<dynamic>();
        box.put('key2', 'hello');
        box.put('key1', 'world');
        box.put('key2', 'hello2');
        expect(box.keyAt(0), 'key1');
        expect(box.keyAt(1), 'key2');
      });
    });

    test('.containsKey()', () async {
      final box = await openTestBox<dynamic>();
      expect(box.containsKey('key1'), false);
      box.put('key1', 'hello');
      expect(box.containsKey('key1'), true);
    });

    group('.get()', () {
      test('non-existing key returns null', () async {
        final box = await openTestBox<dynamic>();
        expect(box.get('key1'), null);
        box.put('key1', true);
        expect(box.get('key2'), null);
      });

      test('non-existing key returns default value', () async {
        final box = await openTestBox<dynamic>();
        expect(box.get('key1', defaultValue: 'hello'), 'hello');
        box.put('key1', true);
        expect(box.get('key2', defaultValue: 'hello'), 'hello');
      });

      test('returns value', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        expect(box.get('key1'), 'hello');
      });
    });

    group('.getAt()', () {
      test('throws IndexError for non-existing index', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.getAt(0), throwsA(isA<IndexError>()));
      });

      test('returns value', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        expect(box.getAt(0), 'hello');
        expect(box.getAt(1), 'world');

        box.putAt(1, 'world2');
        expect(box.getAt(1), 'world2');
      });
    });

    group('operator []', () {
      test('throws ArgumentError for non-int and non-String key', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box[true], throwsArgumentError);
      });

      test('returns null for non-existing key', () async {
        final box = await openTestBox<dynamic>();
        expect(box['key1'], null);
        box.put('key1', true);
        expect(box['key2'], null);
      });

      test('throws IndexError for non-existing index', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box[0], throwsA(isA<IndexError>()));
      });

      test('returns value', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        expect(box['key1'], 'hello');
        expect(box[0], 'hello');
      });
    });

    group('.getAll()', () {
      test('returns empty list for empty keys', () async {
        final box = await openTestBox<dynamic>();
        expect(box.getAll([]), isEmpty);
      });

      test('returns empty list for non-existing keys', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        expect(box.getAll(['key3', 'key4']), isEmpty);
      });

      test('returns values', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        expect(box.getAll(['key1', 'key3']), ['hello', '!']);
      });
    });

    group('.getRange()', () {
      test('throws RangeError for invalid range', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.getRange(-1, 1), throwsRangeError);
        expect(() => box.getRange(0, -1), throwsRangeError);
        expect(() => box.getRange(1, 0), throwsRangeError);
        expect(() => box.getRange(0, 1), throwsRangeError);
      });

      test('returns empty list for empty range', () async {
        final box = await openTestBox<dynamic>();
        box.add('hello');
        expect(box.getRange(0, 0), isEmpty);
      });

      test('returns values', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        expect(box.getRange(0, 2), ['hello', 'world']);
      });
    });

    group('.getBetween()', () {
      test('returns all values if start end end key are null', () async {
        final box = await openTestBox<dynamic>();
        box.add('hello');
        box.put('key', 'value');
        expect(box.getBetween(), ['value']);
      });

      test('returns empty list if start key is greater than end key', () async {
        final box = await openTestBox<dynamic>();
        box.put('a', 'value1');
        box.put('b', 'value2');
        expect(box.getBetween(startKey: 'b', endKey: 'a'), isEmpty);
      });

      test('returns values', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        expect(box.getBetween(), ['hello', 'world', '!']);
        expect(box.getBetween(startKey: 'key2'), ['world', '!']);
        expect(box.getBetween(endKey: 'key2'), ['hello', 'world']);
        expect(box.getBetween(startKey: 'key2', endKey: 'key2'), ['world']);
      });
    });

    group('.put()', () {
      test('overrides existing entry if it exists', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        box.put('key2', 'world2');
        expect(box.getAt(2), 'world2');
        expect(box.keys, ['key1', 'key3', 'key2']);
      });

      test('adds new entry if it does not exist', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        box.put('key4', 'world2');
        expect(box.getAt(3), 'world2');
        expect(box.keys, ['key1', 'key2', 'key3', 'key4']);
      });
    });

    group('.putAt()', () {
      test('throws IndexError for non-existing index', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.putAt(0, 'hello'), throwsA(isA<IndexError>()));
      });

      test('overrides existing entry', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', 'world');
        box.put('key3', '!');
        box.putAt(1, 'world2');
        expect(box.getAt(1), 'world2');
        expect(box.keys, ['key1', 'key3']);
      });
    });

    group('operator []=', () {
      test('throws ArgumentError for non-int and non-String key', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box[true] = 'hello', throwsArgumentError);
      });

      test('overrides existing entry if String key exists', () async {
        final box = await openTestBox<dynamic>();
        box['key1'] = 'hello';
        box['key2'] = 'world';
        box['key3'] = '!';
        box['key2'] = 'world2';
        expect(box.getAt(2), 'world2');
        expect(box.keys, ['key1', 'key3', 'key2']);
      });

      test('adds new entry if String key does not exist', () async {
        final box = await openTestBox<dynamic>();
        box['key1'] = 'hello';
        box['key2'] = 'world';
        box['key3'] = '!';
        box['key4'] = 'world2';
        expect(box.getAt(3), 'world2');
        expect(box.keys, ['key1', 'key2', 'key3', 'key4']);
      });

      test('throws IndexError for non-existing index', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box[0] = 'hello', throwsA(isA<IndexError>()));
      });

      test('overrides existing entry if int key exists', () async {
        final box = await openTestBox<dynamic>();
        box.add('hello');
        box.add('world');
        box.add('!');
        box[1] = 'world2';
        expect(box.getAt(1), 'world2');
        expect(box.keys, isEmpty);
      });
    });

    test('.putAll()', () async {
      final box = await openTestBox<dynamic>();
      box.putAll({'key1': 'hello', 'key2': 'world'});
      expect(box.getAt(0), 'hello');
      expect(box.getAt(1), 'world');
      expect(box.keys, ['key1', 'key2']);

      box.putAll({'key3': '!', 'key1': 'hello2'});
      expect(box.keys, ['key2', 'key3', 'key1']);
      expect(box.getAt(0), 'world');
      expect(box.getAt(1), '!');
      expect(box.getAt(2), 'hello2');
    });

    group('.putRange()', () {
      test('throws RangeError for invalid range', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.putRange(-1, 1, ['hello']), throwsRangeError);
        expect(() => box.putRange(0, -1, ['hello']), throwsRangeError);
        expect(() => box.putRange(1, 0, ['hello']), throwsRangeError);
        expect(() => box.putRange(0, 1, ['hello']), throwsRangeError);
      });

      test('does nothing for empty range', () async {
        final box = await openTestBox<dynamic>();
        box.putRange(0, 0, ['hello']);
        expect(box.keys, isEmpty);
      });

      test('overrides existing entries', () async {
        final box = await openTestBox<dynamic>();
        box.putAll({
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
          'key4': 'value4',
        });
        box.putRange(1, 3, ['newValue2', 'newValue3']);
        expect(box.getAt(0), 'value1');
        expect(box.getAt(1), 'newValue2');
        expect(box.getAt(2), 'newValue3');
        expect(box.getAt(3), 'value4');
        expect(box.keys, ['key1', 'key4']);
      });
    });

    test('.add()', () async {
      final box = await openTestBox<dynamic>();
      box.add('hello');
      box.add('world');
      box.add('!');
      expect(box.getAt(0), 'hello');
      expect(box.getAt(1), 'world');
      expect(box.getAt(2), '!');
      expect(box.keys, isEmpty);
    });

    test('.addAll()', () async {
      final box = await openTestBox<dynamic>();
      box.addAll(['hello', 'world']);
      expect(box.getAt(0), 'hello');
      expect(box.getAt(1), 'world');
      expect(box.keys, isEmpty);

      box.addAll(['!', 'hello2']);
      expect(box.getAt(0), 'hello');
      expect(box.getAt(1), 'world');
      expect(box.getAt(2), '!');
      expect(box.getAt(3), 'hello2');
      expect(box.keys, isEmpty);
    });

    group('.delete()', () {
      test('returns false for non-existing key', () async {
        final box = await openTestBox<dynamic>();
        box.put('key2', true);
        box.add(false);
        expect(box.delete('key1'), false);
        expect(box.length, 2);
      });

      test('returns true for existing key', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', true);
        box.add(false);
        expect(box.delete('key1'), true);
        expect(box.length, 2);
      });
    });

    group('.deleteAt()', () {
      test('throws IndexError for non-existing index', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.deleteAt(0), throwsA(isA<IndexError>()));
      });

      test('deletes entry', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', true);
        box.add(false);
        box.deleteAt(1);
        expect(box.length, 2);
        expect(box.keys, ['key1']);
      });
    });

    group('.deleteAll()', () {
      test('returns 0 for empty keys', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', true);
        box.add(false);
        expect(box.deleteAll([]), 0);
        expect(box.length, 3);
      });

      test('returns 0 for non-existing keys', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', true);
        box.add(false);
        expect(box.deleteAll(['key3', 'key4']), 0);
        expect(box.length, 3);
      });

      test('returns number of deleted entries', () async {
        final box = await openTestBox<dynamic>();
        box.put('key1', 'hello');
        box.put('key2', true);
        box.add(false);
        expect(box.deleteAll(['key1', 'key3', 'key2']), 2);
        expect(box.length, 1);
        expect(box.keys, isEmpty);
      });
    });

    group('.deleteRange()', () {
      test('throws RangeError for invalid range', () async {
        final box = await openTestBox<dynamic>();
        expect(() => box.deleteRange(-1, 1), throwsRangeError);
        expect(() => box.deleteRange(0, -1), throwsRangeError);
        expect(() => box.deleteRange(1, 0), throwsRangeError);
        expect(() => box.deleteRange(0, 1), throwsRangeError);
      });

      test('does nothing for empty range', () async {
        final box = await openTestBox<dynamic>();
        box.add('hello');
        box.deleteRange(0, 0);
        expect(box.length, 1);
      });

      test('deletes entries', () async {
        final box = await openTestBox<dynamic>();
        box.putAll({
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
          'key4': 'value4',
        });
        box.deleteRange(1, 3);
        expect(box.length, 2);
        expect(box.keys, ['key1', 'key4']);
      });
    });
  });
}
