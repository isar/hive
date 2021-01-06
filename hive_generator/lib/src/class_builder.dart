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

  void _buildReadParams(
      StringBuffer code, ConstructorElement constr, List<AdapterField> fields) {
    // The constructor is null only on Built classes, and because of that, this
    // loop gets skipped, so every field still needs to be initialized, and they
    // are via the builder setters.
    for (var param in constr?.parameters ?? <ParameterElement>[]) {
      var field = fields.firstOrNullWhere((it) => it.name == param.name);
      // Final fields
      field ??= getters.firstOrNullWhere((it) => it.name == param.name);
      if (field != null) {
        if (param.isNamed) {
          code.write('${param.name}: ');
        }
        code.writeln('${_cast(param.type, 'fields[${field.index}]')},');
        fields.remove(field);
      }
    }

    code.writeln(')');

    // There may still be fields to initialize that were not in the constructor
    // as initializing formals. We do so using cascades.
    for (var field in fields) {
      code.writeln(
          '..${field.name} = ${_cast(field.type, 'fields[${field.index}]')}');
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

    final builtType = cls.interfaces.singleWhere(isBuilt, orElse: () => null);
    if (builtType == null) {
      code.writeln('    return ${cls.name}(');

      var constr = cls.constructors.firstOrNullWhere((it) => it.name.isEmpty);
      check(constr != null, 'Provide an unnamed constructor.');

      _buildReadParams(code, constr, setters.toList());
    } else {
      // Find the builder
      final builderType = builtType.typeArguments[1];

      var builderName = builderType?.element?.name ?? builderType?.name;
      // In case the builder is being generated, we assume it has the default
      // name
      if (builderName == null || builderType.isDynamic) {
        builderName = '${cls.name}Builder';
      }

      // Instantiate the builder
      code.writeln('    return ($builderName(');

      // Initialize the parameters
      _buildReadParams(
        code,
        null,
        // We are assuming every getter in the built class has an corresponding
        // setter on the Builder class. An reasonable assumption.
        getters.toList(),
      );

      // Build the class
      code.write(').build()');
    }

    code.writeln(';');

    return code.toString();
  }

  String _typeParamsString(DartType type) {
    var paramType = type as ParameterizedType;
    var typeParams = paramType.typeArguments.map(_displayString);
    return typeParams.join(', ');
  }

  String _builtCast(DartType type, String variable) {
    if (builtListChecker.isExactlyType(type)) {
      return 'ListBuilder<${_typeParamsString(type)}>($variable as List)';
    } else if (builtSetChecker.isExactlyType(type)) {
      return 'SetBuilder<${_typeParamsString(type)}>($variable as List)';
    } else if (builtMapChecker.isExactlyType(type)) {
      return 'MapBuilder<${_typeParamsString(type)}>($variable as Map)';
    }
    return '($variable as ${_displayString(type)})?.toBuilder()';
  }

  String _cast(DartType type, String variable) {
    if (isBuiltOrBuiltCollection(type)) {
      return _builtCast(type, variable);
    } else if (hiveListChecker.isExactlyType(type)) {
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
      var cast = '';
      if (listChecker.isExactlyType(type)) {
        cast = '?.toList()';
      } else if (setChecker.isExactlyType(type)) {
        cast = '?.toSet()';
      }
      return '?.map((dynamic e)=> ${_cast(arg, 'e')})$cast';
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
          'MapEntry(${_cast(arg1, 'k')},${_cast(arg2, 'v')}))';
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
      var value = _convertWritableValue(field.type, 'obj.${field.name}');
      code.writeln('''
      ..writeByte(${field.index})
      ..write($value)''');
    }
    code.writeln(';');

    return code.toString();
  }

  String _convertWritableValue(DartType type, String accessor) {
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
