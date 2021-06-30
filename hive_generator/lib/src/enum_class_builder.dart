import 'package:analyzer/dart/element/element.dart';
import 'package:hive_generator/src/builder.dart';

class EnumClassBuilder extends Builder {
  EnumClassBuilder(
    ClassElement cls,
  ) : super(cls, [], []);

  @override
  String buildRead() {
    // Read the name of the enum class from the single field
    var code = StringBuffer()
      ..writeln('return ${cls.name}.valueOf(reader.read() as String);');
    return code.toString();
  }

  @override
  String buildWrite() {
    // Write the name of the enum class as the single field.
    var code = StringBuffer()
      ..writeln('writer') //
      ..writeln('..write(obj.name);');
    return code.toString();
  }
}
