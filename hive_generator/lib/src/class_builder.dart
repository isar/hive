import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:hive/hive.dart';
import 'package:hive_generator/src/builder.dart';
import 'package:hive_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dartx/dartx.dart';
import 'package:built_value/built_value.dart' as bv;
import 'package:built_collection/built_collection.dart';

import 'type_adapter_generator.dart';

class ClassBuilder extends _ClassBuilderBase {
  ClassBuilder(
    ClassElement cls,
    List<AdapterField> getters,
    List<AdapterField> setters,
  ) : super(cls, getters, setters);

  var builtValueChecker = const TypeChecker.fromRuntime(bv.BuiltValue);

  var builtChecker = const TypeChecker.fromRuntime(bv.Built);
  var builtListChecker = const TypeChecker.fromRuntime(BuiltList);
  var builtSetChecker = const TypeChecker.fromRuntime(BuiltSet);
  var builtMapChecker = const TypeChecker.fromRuntime(BuiltMap);

  var builderChecker = const TypeChecker.fromRuntime(bv.Builder);
  var listBuilderChecker = const TypeChecker.fromRuntime(ListBuilder);
  var setBuilderChecker = const TypeChecker.fromRuntime(SetBuilder);
  var mapBuilderChecker = const TypeChecker.fromRuntime(MapBuilder);

  bool get isThisBuilt => cls.interfaces.any(builtChecker.isExactlyType);
  DartType get builderType => isThisBuilt
      ? cls.interfaces
          .singleWhere(builtChecker.isExactlyType)
          .typeArguments
          .last
      : throw StateError(
          'Tried to find the builderType on ${cls.name}, which is not Built.');

  bool _nestedBuildersFromAnnotation() {
    final annotation =
        cls.metadata.map((e) => e.computeConstantValue()).singleWhere(
              (e) => builtValueChecker.isExactlyType(e.type),
              orElse: () => null,
            );
    if (annotation == null) {
      return true;
    }
    final reader = ConstantReader(annotation);
    final nestedBuilders = reader.read('nestedBuilders');
    if (nestedBuilders.isNull) {
      return true;
    }
    return nestedBuilders.boolValue;
  }

  @override
  void buildReadConstructor(StringBuffer code) {
    if (!isThisBuilt) {
      return super.buildReadConstructor(code);
    }

    String builderName;
    List<BuiltAdapterField> fields;

    // In case the builder is being generated, we assume it has the default
    // name and fields
    if (builderType?.isDynamic ?? true) {
      builderName = '${cls.name}Builder';

      // We want to set an builder instead of the built class depending on the
      // @BuiltValue annotation, but we cant express this easily with DartType,
      // so we pass this info to cast()
      final nestedBuilders = _nestedBuildersFromAnnotation();

      // The fields that need to be set on the cascade are the getters in the
      // built class, because they have an corresponding setter in the builder.
      fields = getters.map((field) => field.toBuilt(nestedBuilders)).toList();
    } else {
      // The builder type was manually created, therefore we look it up for
      // @HiveField annotations
      final builderCls = builderType.element as ClassElement;
      builderName = builderCls.name;
      var gettersAndSetters = getAccessors(builderCls, builderCls.library);

      var setters = gettersAndSetters[1];
      verifyFieldIndices(setters);

      // The fields that need to be set on the cascade are the setters in the
      // builder class.
      //
      // We do not need to look for nested fieldss in the annotation, as this
      // information is contained in each setter's DartType in most cases,
      // allowing for correct casting.
      fields = setters.map((field) => field.toBuilt(false)).toList();

      // The edge case is when the type is an Builder which is being generated.
      // In this case we set nestedBuilders = true and the type to the Built
      // type as a workaround.
      final clsFieldMap = {for (final field in getters) field.index: field};
      for (final builderField in fields) {
        final builtField = clsFieldMap[builderField.index];
        if (builtField == null) {
          continue;
        }
        if (!builderField.type.isDynamic || builtField.type.isDynamic) {
          continue;
        }
        // builderField is dynamic, while builtField isnt. this MAY be the edge
        // case. To resolve it, we will check if builtField is an Built value.
        // If so, this is the edge case
        if (!isBuilt(builtField.type)) {
          continue;
        }
        builderField
          ..type = builtField.type
          ..nestedBuilders = true;
      }
    }

    // Instantiate the builder
    code.writeln('    return ($builderName()');

    // Initialize the parameters using setters with cascades on the builder.
    for (var field in fields) {
      code.writeln('..${field.name} = ${cast(
        field.type,
        'fields[${field.index}]',
        field.builtValueNestedBuilders,
      )}');
    }

    // Build the class
    code.write(').build()');
  }

  String _castBuiltCollection(
    DartType type,
    String variable, {
    bool nestedBuilders,
  }) {
    String builderConstructor;
    String typeToBeCasted;
    String castExpr = '';
    // Wether or not we should call build() on the end.
    //
    // This when the user annotated with nestedBuilders = false, so the Builder
    // for that class expects an Built value, instead of a builder.
    //
    // This is not the case when either nestedBuilders is true or ommited, or
    // when an custom builder was specified with an ListBuilder for example.
    var shouldBeBuilt = isBuiltCollection(type) && (nestedBuilders != true);

    if (builtMapChecker.isExactlyType(type) ||
        mapBuilderChecker.isExactlyType(type)) {
      builderConstructor = 'MapBuilder';
      typeToBeCasted = 'Map';
      castExpr = castMap(type, nullable: false);
    } else {
      typeToBeCasted = 'Iterable';
      castExpr = castIterable(type, nullable: false);
      if (builtSetChecker.isExactlyType(type) ||
          setBuilderChecker.isExactlyType(type)) {
        builderConstructor = 'SetBuilder';
      }
      if (builtListChecker.isExactlyType(type) ||
          listBuilderChecker.isExactlyType(type)) {
        builderConstructor = 'ListBuilder';
      }
    }
    check(builderConstructor != null && typeToBeCasted != null,
        'Unrecognized built_collection type ${_displayString(type)}');

    final castedVariable = castExpr.isEmpty
        ? '$variable as $typeToBeCasted'
        : '($variable as $typeToBeCasted)$castExpr';

    final buildExpression = '$builderConstructor<${_typeParamsString(type)}>'
        '($castedVariable)'
        '${shouldBeBuilt ? '.build()' : ''}';

    return '$variable == null ? null : $buildExpression';
  }

  @override
  String cast(
    DartType type,
    String variable, [
    bool nestedBuilders = false,
  ]) {
    if (!isBuiltOrBuiltCollection(type) &&
        !isBuilderOrCollectionBuilder(type)) {
      // This value needs no special treatment.
      return super.cast(type, variable);
    }

    if ((isBuilt(type) && nestedBuilders) || isBuilder(type)) {
      // We need to call .toBuilder(), because variable is always an Built
      // value, but we need an Builder value.
      return '($variable as ${_displayString(type)})?.toBuilder()';
    }

    if (isBuiltCollection(type) || isCollectionBuilder(type)) {
      return _castBuiltCollection(type, variable, nestedBuilders ?? false);
    }

    // We just need to cast the value. This happens when the type is of a Built
    // value in a custom Builder which accepts the plain Built value instead of
    // a builder, for example.
    return '$variable as ${_displayString(type)}';
  }

  @override
  String castIterable(DartType type, {bool nullable = true}) {
    var paramType = type as ParameterizedType;
    var arg = paramType.typeArguments.first;
    if (isBuiltCollection(arg) || isCollectionBuilder(arg)) {
      return '${nullable ? '?' : ''}'
          '.map((dynamic e)=> '
          '${cast(arg, 'e', nullable: nullable)})';
    } else if (isBuiltCollection(type) || isCollectionBuilder(type)) {
      // Built collections use List<T>.from and Map<K, V>.from, so casting
      // manually is not needed.
      return '';
    } else {
      return super.castIterable(type);
    }
  }

  @override
  String castMap(DartType type, {bool nullable = true}) {
    var paramType = type as ParameterizedType;
    var arg1 = paramType.typeArguments[0];
    var arg2 = paramType.typeArguments[1];
    if (isBuiltCollection(arg1) ||
        isCollectionBuilder(arg1) ||
        isBuiltCollection(arg2) ||
        isCollectionBuilder(arg2)) {
      return '${nullable ? '?' : ''}'
          '.map((dynamic k, dynamic v)=>'
          'MapEntry(${cast(arg1, 'k', nullable: nullable)},'
          '${cast(arg2, 'v', nullable: nullable)}))';
    }
    return super.castMap(type);
  }

  bool isBuilt(DartType type) {
    return builtChecker.isAssignableFromType(type);
  }

  bool isBuiltCollection(DartType type) {
    return builtListChecker.isExactlyType(type) ||
        builtSetChecker.isExactlyType(type) ||
        builtMapChecker.isExactlyType(type);
  }

  bool isBuiltOrBuiltCollection(DartType type) {
    return isBuilt(type) || isBuiltCollection(type);
  }

  bool isBuilder(DartType type) {
    return builderChecker.isAssignableFromType(type);
  }

  bool isCollectionBuilder(DartType type) {
    return listBuilderChecker.isExactlyType(type) ||
        setBuilderChecker.isExactlyType(type) ||
        mapBuilderChecker.isExactlyType(type);
  }

  bool isBuilderOrCollectionBuilder(DartType type) {
    return isBuilder(type) || isCollectionBuilder(type);
  }

  String _typeParamsString(DartType type) {
    var paramType = type as ParameterizedType;
    var typeParams = paramType.typeArguments.map(_displayString);
    return typeParams.join(', ');
  }

  String _convertWritableBuiltMap(DartType type, String accessor) {
    var paramType = type as ParameterizedType;
    var arg1 = paramType.typeArguments[0];
    var arg2 = paramType.typeArguments[1];
    if (isBuiltCollection(arg1) || isBuiltCollection(arg2)) {
      return '$accessor?.toMap()?.map'
          '((k, v) => MapEntry('
          '${convertWritableValue(arg1, 'k')}, '
          '${convertWritableValue(arg2, 'v')}))';
    }
    return '$accessor?.toMap()';
  }

  String _convertWritableBuiltIterable(DartType type, String accessor) {
    var paramType = type as ParameterizedType;
    var arg = paramType.typeArguments.single;
    if (isBuiltCollection(arg)) {
      return '$accessor?.toList()?.map'
          '((e) => '
          '${convertWritableValue(arg, 'e')})';
    }
    return '$accessor?.toList()';
  }

  @override
  String convertWritableValue(DartType type, String accessor) {
    if (!isBuiltCollection(type)) {
      return super.convertWritableValue(type, accessor);
    }
    if (builtMapChecker.isExactlyType(type)) {
      return _convertWritableBuiltMap(type, accessor);
    }
    return _convertWritableBuiltIterable(type, accessor);
  }
}

class _ClassBuilderBase extends Builder {
  var hiveListChecker = const TypeChecker.fromRuntime(HiveList);
  var listChecker = const TypeChecker.fromRuntime(List);
  var mapChecker = const TypeChecker.fromRuntime(Map);
  var setChecker = const TypeChecker.fromRuntime(Set);
  var iterableChecker = const TypeChecker.fromRuntime(Iterable);
  var uint8ListChecker = const TypeChecker.fromRuntime(Uint8List);

  _ClassBuilderBase(
      ClassElement cls, List<AdapterField> getters, List<AdapterField> setters)
      : super(cls, getters, setters);

  void buildReadConstructor(StringBuffer code) {
    code.writeln('    return ${cls.name}(');

    var constr = cls.constructors.firstOrNullWhere((it) => it.name.isEmpty);
    check(constr != null, 'Provide an unnamed constructor.');

    // The remaining fields to be set later
    var fields = setters.toList();

    for (var param in constr?.parameters ?? <ParameterElement>[]) {
      var field = fields.firstOrNullWhere((it) => it.name == param.name);
      // Final fields
      field ??= getters.firstOrNullWhere((it) => it.name == param.name);
      if (field != null) {
        if (param.isNamed) {
          code.write('${param.name}: ');
        }
        code.writeln('${cast(param.type, 'fields[${field.index}]')},');
        fields.remove(field);
      }
    }

    code.writeln(')');

    // There may still be fields to initialize that were not in the constructor
    // as initializing formals. We do so using cascades.
    for (var field in fields) {
      code.writeln(
          '..${field.name} = ${cast(field.type, 'fields[${field.index}]')}');
    }
  }

  @override
  String buildRead() {
    var code = StringBuffer();
    code.writeln('''
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };
    ''');

    buildReadConstructor(code);

    code.writeln(';');

    return code.toString();
  }

  String cast(DartType type, String variable) {
    if (hiveListChecker.isExactlyType(type)) {
      return '($variable as HiveList)?.castHiveList()';
    } else if (iterableChecker.isAssignableFromType(type) &&
        !isUint8List(type)) {
      return '($variable as List)${castIterable(type)}';
    } else if (mapChecker.isExactlyType(type)) {
      return '($variable as Map)${castMap(type)}';
    } else {
      return '$variable as ${_displayString(type)}';
    }
  }

  bool isMapOrIterable(DartType type) {
    return listChecker.isExactlyType(type) ||
        setChecker.isExactlyType(type) ||
        iterableChecker.isExactlyType(type) ||
        mapChecker.isExactlyType(type);
  }

  bool isUint8List(DartType type) {
    return uint8ListChecker.isExactlyType(type);
  }

  String castIterable(DartType type) {
    var paramType = type as ParameterizedType;
    var arg = paramType.typeArguments.first;
    if (isMapOrIterable(arg) && !isUint8List(arg)) {
      var castSuffix = '';
      if (listChecker.isExactlyType(type)) {
        castSuffix = '?.toList()';
      } else if (setChecker.isExactlyType(type)) {
        castSuffix = '?.toSet()';
      }
      return '?.map((dynamic e)=> ${cast(arg, 'e')})$castSuffix';
    } else {
      return '?.cast<${_displayString(arg)}>()';
    }
  }

  String castMap(DartType type) {
    var paramType = type as ParameterizedType;
    var arg1 = paramType.typeArguments[0];
    var arg2 = paramType.typeArguments[1];
    if (isMapOrIterable(arg1) || isMapOrIterable(arg2)) {
      return '?.map((dynamic k, dynamic v)=>'
          'MapEntry(${cast(arg1, 'k')},${cast(arg2, 'v')}))';
    } else {
      return '?.cast<${_displayString(arg1)}, '
          '${_displayString(arg2)}>()';
    }
  }

  @override
  String buildWrite() {
    var code = StringBuffer();
    code.writeln('writer');
    code.writeln('..writeByte(${getters.length})');
    for (var field in getters) {
      var value = convertWritableValue(field.type, 'obj.${field.name}');
      code.writeln('''
      ..writeByte(${field.index})
      ..write($value)''');
    }
    code.writeln(';');

    return code.toString();
  }

  String convertWritableValue(DartType type, String accessor) {
    if (setChecker.isExactlyType(type) || iterableChecker.isExactlyType(type)) {
      return '$accessor?.toList()';
    } else {
      return accessor;
    }
  }
}

String _displayString(dynamic e) {
  try {
    return e.getDisplayString(withNullability: false) as String;
  } catch (error) {
    if (error is TypeError) {
      return e.getDisplayString() as String;
    } else {
      rethrow;
    }
  }
}
