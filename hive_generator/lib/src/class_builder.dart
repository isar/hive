import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:hive_generator/src/builder.dart';
import 'package:source_gen/source_gen.dart';

class ClassBuilder extends Builder {
  var listChecker = const TypeChecker.fromRuntime(List);
  var mapChecker = const TypeChecker.fromRuntime(Map);

  ClassBuilder(String cls, Map<int, FieldElement> fields) : super(cls, fields);

  @override
  String buildRead() {
    var code = StringBuffer();
    code.writeln('''
    var obj = $cls();
    var numOfFields = reader.readByte();
    for (var i = 0; i < numOfFields; i++) {
      switch(reader.readByte()) {''');

    fields.forEach((index, field) {
      code.writeln('''
        case $index:
          obj.${field.name} = reader.read()${_cast(field.type)};
          break;''');
    });

    code.writeln('''
    }}
    return obj;''');

    return code.toString();
  }

  String _cast(DartType type) {
    if (listChecker.isExactlyType(type)) {
      var paramType = type as ParameterizedType;
      var arg = paramType.typeArguments[0];
      return '?.map((dynamic e)=> e${_cast(arg)})?.toList()';
    } else if (mapChecker.isExactlyType(type)) {
      var paramType = type as ParameterizedType;
      var arg1 = paramType.typeArguments[0];
      var arg2 = paramType.typeArguments[1];
      return '?.map((dynamic k, dynamic v)=> MapEntry(k${_cast(arg1)},v${_cast(arg2)}))?.toMap()';
    } else {
      return ' as ${type.name}';
    }
  }

  @override
  String buildWrite() {
    var code = StringBuffer();
    code.writeln('writer.writeByte(${fields.length});');
    fields.forEach((index, field) {
      code.writeln('''
      writer.writeByte($index);
      writer.write(obj.${field.name});''');
    });

    return code.toString();
  }
}
