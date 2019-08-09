import 'package:analyzer/dart/element/element.dart';
import 'package:hive_generator/src/builder.dart';

class EnumBuilder extends Builder {
  EnumBuilder(String cls, Map<int, FieldElement> fields) : super(cls, fields);

  @override
  String buildRead() {
    var code = StringBuffer();
    code.writeln('switch(reader.readByte()) {');

    fields.forEach((index, field) {
      code.writeln('''
        case $index:
          return $cls.${field.name};''');
    });

    code.writeln('''
      default:
        return null;
      }''');

    return code.toString();
  }

  @override
  String buildWrite() {
    var code = StringBuffer();
    code.writeln('switch(obj) {');

    fields.forEach((index, field) {
      code.writeln('''
        case $cls.${field.name}:
          writer.writeByte($index);
          break;''');
    });

    code.writeln('}');

    return code.toString();
  }
}
