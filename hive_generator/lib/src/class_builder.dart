import 'dart:typed_data';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:hive/hive.dart';
import 'package:hive_generator/src/builder.dart';
import 'package:hive_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dartx/dartx.dart';

class ClassBuilder extends Builder {
  var hiveListChecker = const TypeChecker.fromRuntime(HiveList);
  var listChecker = const TypeChecker.fromRuntime(List);
  var mapChecker = const TypeChecker.fromRuntime(Map);
  var setChecker = const TypeChecker.fromRuntime(Set);
  var iterableChecker = const TypeChecker.fromRuntime(Iterable);
  var uint8ListChecker = const TypeChecker.fromRuntime(Uint8List);

  /// The built type checkers. They aren't from runtime because otherwise we
  /// would have to depend on both packages. Altough [TypeChecker.fromUrl] is
  /// not reccomended because of it's brittleness, this should not be a problem,
  /// as these classes are in the same url since the packages got published
  /// 6 years ago.
  var builtChecker =
      const TypeChecker.fromUrl('package:built_value/built_value.dart#Built');
  var builtListChecker = const TypeChecker.fromUrl(
      'package:built_collection/src/list.dart#BuiltList');
  var builtSetChecker = const TypeChecker.fromUrl(
      'package:built_collection/src/set.dart#BuiltSet');
  var builtMapChecker = const TypeChecker.fromUrl(
      'package:built_collection/src/map.dart#BuiltMap');

  ClassBuilder(
      ClassElement cls, List<AdapterField> getters, List<AdapterField> setters)
      : super(cls, getters, setters);

  void _buildBaseReadConstructor(StringBuffer code) {
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

  void _buildBuiltReadConstructor(StringBuffer code, InterfaceType builtType) {
    // Find the builder
    final builderType = builtType.typeArguments[1];

    List<AdapterField> fields;
    var builderName = builderType?.element?.name ?? builderType?.name;
    // In case the builder is being generated, we assume it has the default
    // name and fields
    if (builderName == null || builderType.isDynamic) {
      builderName = '${cls.name}Builder';
      fields = getters;
    } else {
      throw StateError(
          'We do not support custom builders yet. They would generate invalid code');
    }

    // Instantiate the builder
    code.writeln('    return ($builderName()');

    // Initialize the parameters using setters with cascades on the builder.
    for (var field in fields) {
      code.writeln(
          '..${field.name} = ${cast(field.type, 'fields[${field.index}]')}');
    }

    // Build the class
    code.write(').build()');
  }

  void buildReadConstructor(StringBuffer code) {
    final builtType = cls.interfaces
        .singleWhere(builtChecker.isExactlyType, orElse: () => null);
    if (builtType == null) {
      return _buildBaseReadConstructor(code);
    }
    return _buildBuiltReadConstructor(code, builtType);
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

  String _typeParamsString(DartType type) {
    var paramType = type as ParameterizedType;
    var typeParams = paramType.typeArguments.map(_displayString);
    return typeParams.join(', ');
  }

  String _castBuilt(DartType type, String variable) {
    final pfx = '$variable == null ? null : ';
    if (builtListChecker.isExactlyType(type)) {
      return '${pfx}ListBuilder<${_typeParamsString(type)}>($variable as List)';
    } else if (builtSetChecker.isExactlyType(type)) {
      return '${pfx}SetBuilder<${_typeParamsString(type)}>($variable as List)';
    } else if (builtMapChecker.isExactlyType(type)) {
      return '${pfx}MapBuilder<${_typeParamsString(type)}>($variable as Map)';
    }
    return '($variable as ${_displayString(type)})?.toBuilder()';
  }

  String cast(DartType type, String variable) {
    if (isBuiltOrBuiltCollection(type)) {
      return _castBuilt(type, variable);
    }
    return _castBase(type, variable);
  }

  String _castBase(DartType type, String variable) {
    if (hiveListChecker.isExactlyType(type)) {
      return '($variable as HiveList)?.castHiveList()';
    } else if (iterableChecker.isAssignableFromType(type) &&
        !isUint8List(type)) {
      return '($variable as List)${_castIterable(type)}';
    } else if (mapChecker.isExactlyType(type)) {
      return '($variable as Map)${_castMap(type)}';
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

  String _castIterable(DartType type) {
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

  String _castMap(DartType type) {
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
    if (isBuiltCollection(type)) {
      return builtMapChecker.isExactlyType(type)
          ? '$accessor?.toMap()'
          : '$accessor?.toList()';
    } else if (setChecker.isExactlyType(type) ||
        iterableChecker.isExactlyType(type)) {
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
