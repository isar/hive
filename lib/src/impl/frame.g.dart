// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetFrameCollection on Isar {
  IsarCollection<int, Frame> get frames => this.collection();
}

const FrameSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Frame',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'typeId',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'key',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'value',
        type: IsarType.json,
      ),
    ],
    indexes: [
      IsarIndexSchema(
        name: 'key',
        properties: [
          "key",
        ],
        unique: true,
        hash: true,
      ),
    ],
  ),
  converter: IsarObjectConverter<int, Frame>(
    serialize: serializeFrame,
    deserialize: deserializeFrame,
    deserializeProperty: deserializeFrameProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeFrame(IsarWriter writer, Frame object) {
  IsarCore.writeLong(writer, 1, object.typeId ?? -9223372036854775808);
  {
    final value = object.key;
    if (value == null) {
      IsarCore.writeNull(writer, 2);
    } else {
      IsarCore.writeString(writer, 2, value);
    }
  }
  IsarCore.writeString(writer, 3, isarJsonEncode(object.value));
  return object.id;
}

@isarProtected
Frame deserializeFrame(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final int? _typeId;
  {
    final value = IsarCore.readLong(reader, 1);
    if (value == -9223372036854775808) {
      _typeId = null;
    } else {
      _typeId = value;
    }
  }
  final String? _key;
  _key = IsarCore.readString(reader, 2);
  final dynamic _value;
  _value = isarJsonDecode(IsarCore.readString(reader, 3) ?? 'null') ?? null;
  final object = Frame(
    id: _id,
    typeId: _typeId,
    key: _key,
    value: _value,
  );
  return object;
}

@isarProtected
dynamic deserializeFrameProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      {
        final value = IsarCore.readLong(reader, 1);
        if (value == -9223372036854775808) {
          return null;
        } else {
          return value;
        }
      }
    case 2:
      return IsarCore.readString(reader, 2);
    case 3:
      return isarJsonDecode(IsarCore.readString(reader, 3) ?? 'null') ?? null;
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _FrameUpdate {
  bool call({
    required int id,
    int? typeId,
    String? key,
  });
}

class _FrameUpdateImpl implements _FrameUpdate {
  const _FrameUpdateImpl(this.collection);

  final IsarCollection<int, Frame> collection;

  @override
  bool call({
    required int id,
    Object? typeId = ignore,
    Object? key = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (typeId != ignore) 1: typeId as int?,
          if (key != ignore) 2: key as String?,
        }) >
        0;
  }
}

sealed class _FrameUpdateAll {
  int call({
    required List<int> id,
    int? typeId,
    String? key,
  });
}

class _FrameUpdateAllImpl implements _FrameUpdateAll {
  const _FrameUpdateAllImpl(this.collection);

  final IsarCollection<int, Frame> collection;

  @override
  int call({
    required List<int> id,
    Object? typeId = ignore,
    Object? key = ignore,
  }) {
    return collection.updateProperties(id, {
      if (typeId != ignore) 1: typeId as int?,
      if (key != ignore) 2: key as String?,
    });
  }
}

extension FrameUpdate on IsarCollection<int, Frame> {
  _FrameUpdate get update => _FrameUpdateImpl(this);

  _FrameUpdateAll get updateAll => _FrameUpdateAllImpl(this);
}

sealed class _FrameQueryUpdate {
  int call({
    int? typeId,
    String? key,
  });
}

class _FrameQueryUpdateImpl implements _FrameQueryUpdate {
  const _FrameQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Frame> query;
  final int? limit;

  @override
  int call({
    Object? typeId = ignore,
    Object? key = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (typeId != ignore) 1: typeId as int?,
      if (key != ignore) 2: key as String?,
    });
  }
}

extension FrameQueryUpdate on IsarQuery<Frame> {
  _FrameQueryUpdate get updateFirst => _FrameQueryUpdateImpl(this, limit: 1);

  _FrameQueryUpdate get updateAll => _FrameQueryUpdateImpl(this);
}

class _FrameQueryBuilderUpdateImpl implements _FrameQueryUpdate {
  const _FrameQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Frame, Frame, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? typeId = ignore,
    Object? key = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (typeId != ignore) 1: typeId as int?,
        if (key != ignore) 2: key as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension FrameQueryBuilderUpdate on QueryBuilder<Frame, Frame, QOperations> {
  _FrameQueryUpdate get updateFirst =>
      _FrameQueryBuilderUpdateImpl(this, limit: 1);

  _FrameQueryUpdate get updateAll => _FrameQueryBuilderUpdateImpl(this);
}

extension FrameQueryFilter on QueryBuilder<Frame, Frame, QFilterCondition> {
  QueryBuilder<Frame, Frame, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 1));
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdGreaterThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdGreaterThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdLessThan(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdLessThanOrEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> typeIdBetween(
    int? lower,
    int? upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 2));
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }
}

extension FrameQueryObject on QueryBuilder<Frame, Frame, QFilterCondition> {}

extension FrameQuerySortBy on QueryBuilder<Frame, Frame, QSortBy> {
  QueryBuilder<Frame, Frame, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByKeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }
}

extension FrameQuerySortThenBy on QueryBuilder<Frame, Frame, QSortThenBy> {
  QueryBuilder<Frame, Frame, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByTypeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByKeyDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Frame, Frame, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }
}

extension FrameQueryWhereDistinct on QueryBuilder<Frame, Frame, QDistinct> {
  QueryBuilder<Frame, Frame, QAfterDistinct> distinctByTypeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }

  QueryBuilder<Frame, Frame, QAfterDistinct> distinctByKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Frame, Frame, QAfterDistinct> distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }
}

extension FrameQueryProperty1 on QueryBuilder<Frame, Frame, QProperty> {
  QueryBuilder<Frame, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Frame, int?, QAfterProperty> typeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Frame, String?, QAfterProperty> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Frame, dynamic, QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }
}

extension FrameQueryProperty2<R> on QueryBuilder<Frame, R, QAfterProperty> {
  QueryBuilder<Frame, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Frame, (R, int?), QAfterProperty> typeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Frame, (R, String?), QAfterProperty> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Frame, (R, dynamic), QAfterProperty> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }
}

extension FrameQueryProperty3<R1, R2>
    on QueryBuilder<Frame, (R1, R2), QAfterProperty> {
  QueryBuilder<Frame, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Frame, (R1, R2, int?), QOperations> typeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Frame, (R1, R2, String?), QOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Frame, (R1, R2, dynamic), QOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }
}
