import 'dart:math';

import 'package:hive/src/util/delegating_list_view_mixin.dart';
import 'package:test/test.dart';

void main() {
  group('DelegatingIterable', () {
    _TestList<String> testList;

    setUp(() {
      testList = _TestList(['a', 'b', 'cc']);
    });

    test('.any()', () {
      expect(testList.any((e) => e == 'b'), isTrue);
      expect(testList.any((e) => e == 'd'), isFalse);
    });

    test('.contains()', () {
      expect(testList.contains('b'), isTrue);
      expect(testList.contains('d'), isFalse);
    });

    test('.elementAt()', () {
      expect(testList.elementAt(1), equals('b'));
    });

    test('.every()', () {
      expect(testList.every((e) => e is String), isTrue);
      expect(testList.every((e) => e == 'b'), isFalse);
    });

    test('.expand()', () {
      expect(testList.expand((e) => e.codeUnits), equals([97, 98, 99, 99]));
    });

    test('.first()', () {
      expect(testList.first, equals('a'));
    });

    test('.firstWhere()', () {
      expect(testList.firstWhere((e) => e == 'b'), equals('b'));
      expect(
          testList.firstWhere((e) => e == 'd', orElse: () => 'e'), equals('e'));
    });

    test('.fold()', () {
      expect(testList.fold('z', (p, e) => p + e), equals('zabcc'));
    });

    test('.forEach()', () {
      final s = StringBuffer();
      testList.forEach(s.write);
      expect(s.toString(), equals('abcc'));
    });

    test('.isEmpty', () {
      expect(testList.isEmpty, isFalse);
      expect(_TestList([]).isEmpty, isTrue);
    });

    test('.isNotEmpty', () {
      expect(testList.isNotEmpty, isTrue);
      expect(_TestList([]).isNotEmpty, isFalse);
    });

    test('.followedBy()', () {
      expect(
          testList.followedBy(['d', 'e']), equals(['a', 'b', 'cc', 'd', 'e']));
      expect(testList.followedBy(testList),
          equals(['a', 'b', 'cc', 'a', 'b', 'cc']));
    });

    test('.forEach()', () {
      final it = testList.iterator;
      expect(it.current, isNull);
      expect(it.moveNext(), isTrue);
      expect(it.current, equals('a'));
      expect(it.moveNext(), isTrue);
      expect(it.current, equals('b'));
      expect(it.moveNext(), isTrue);
      expect(it.current, equals('cc'));
      expect(it.moveNext(), isFalse);
      expect(it.current, isNull);
    });

    test('.join()', () {
      expect(testList.join(), equals('abcc'));
      expect(testList.join(','), equals('a,b,cc'));
    });

    test('.last', () {
      expect(testList.last, equals('cc'));
    });

    test('.lastWhere()', () {
      expect(testList.lastWhere((e) => e == 'b'), equals('b'));
      expect(
          testList.lastWhere((e) => e == 'd', orElse: () => 'e'), equals('e'));
    });

    test('.length', () {
      expect(testList.length, equals(3));
    });

    test('.map()', () {
      expect(testList.map((e) => e.toUpperCase()), equals(['A', 'B', 'CC']));
    });

    test('.reduce()', () {
      expect(
          testList.reduce((value, element) => value + element), equals('abcc'));
    });

    test('single', () {
      expect(() => testList.single, throwsStateError);
      expect(_TestList(['a']).single, equals('a'));
    });

    test('.singleWhere()', () {
      expect(testList.singleWhere((e) => e == 'b'), equals('b'));
      expect(() => testList.singleWhere((e) => e == 'd'), throwsStateError);
      expect(testList.singleWhere((e) => e == 'd', orElse: () => 'X'),
          equals('X'));
    });

    test('.skip()', () {
      expect(testList.skip(1), equals(['b', 'cc']));
    });

    test('.skipWhile()', () {
      expect(testList.skipWhile((e) => e == 'a'), equals(['b', 'cc']));
    });

    test('.take()', () {
      expect(testList.take(1), equals(['a']));
    });

    test('.skipWhile()', () {
      expect(testList.takeWhile((e) => e == 'a'), equals(['a']));
    });

    test('.toList()', () {
      expect(testList.toList(), equals(['a', 'b', 'cc']));
    });

    test('.toSet()', () {
      expect(testList.toSet(), equals(<String>{'a', 'b', 'cc'}));
    });

    test('.where()', () {
      expect(testList.where((e) => e.length == 1), equals(['a', 'b']));
    });
  });
}

class _TestList<T> with DelegatingListViewMixin<T> {
  final List<T> _delegate;

  _TestList(this._delegate);

  @override
  List<T> get delegate => _delegate;

  @override
  void operator []=(int index, T value) => throw UnimplementedError();

  @override
  void add(T value) => throw UnimplementedError();

  @override
  void addAll(Iterable<T> iterable) => throw UnimplementedError();

  @override
  void clear() => throw UnimplementedError();

  @override
  void fillRange(int start, int end, [T fillValue]) =>
      throw UnimplementedError();

  @override
  set first(T value) => throw UnimplementedError();

  @override
  void insert(int index, T element) => throw UnimplementedError();

  @override
  void insertAll(int index, Iterable<T> iterable) => throw UnimplementedError();

  @override
  set last(T value) => throw UnimplementedError();

  @override
  set length(int newLength) => throw UnimplementedError();

  @override
  bool remove(Object value) => throw UnimplementedError();

  @override
  T removeAt(int index) => throw UnimplementedError();

  @override
  T removeLast() => throw UnimplementedError();

  @override
  void removeRange(int start, int end) => throw UnimplementedError();

  @override
  void removeWhere(bool Function(T element) test) => throw UnimplementedError();

  @override
  void replaceRange(int start, int end, Iterable<T> replacement) =>
      throw UnimplementedError();

  @override
  void retainWhere(bool Function(T element) test) => throw UnimplementedError();

  @override
  void setAll(int index, Iterable<T> iterable) => throw UnimplementedError();

  @override
  void setRange(int start, int end, Iterable<T> iterable,
          [int skipCount = 0]) =>
      throw UnimplementedError();

  @override
  void shuffle([Random random]) => throw UnimplementedError();

  @override
  void sort([int Function(T a, T b) compare]) => throw UnimplementedError();
}
