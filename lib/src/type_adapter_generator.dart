import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:hive_generator/src/class_builder.dart';
import 'package:hive_generator/src/enum_builder.dart';
import 'package:hive_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';
import 'package:hive/hive.dart';

class TypeAdapterGenerator extends GeneratorForAnnotation<HiveType> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var cls = getClass(element);
    var fields = getFields(cls);
    var type = element.name;
    var adapterName = getAdapterName(type, annotation);
    var builder =
        cls.isEnum ? EnumBuilder(type, fields) : ClassBuilder(type, fields);
    return '''

    class $adapterName extends TypeAdapter<$type> {
      @override
      $type read(BinaryReader reader) {
        ${builder.buildRead()}
      }

      @override
      void write(BinaryWriter writer, $type obj) {
        ${builder.buildWrite()}
      }
    }
    ''';
  }

  ClassElement getClass(Element element) {
    check(element.kind == ElementKind.CLASS,
        'Only classes or enums are allowed to be annotated with @HiveType.');

    var cls = element as ClassElement;

    check(!cls.isAbstract,
        'Classes annotated with @HiveType must not be abstract.');

    var hasDefaultConstructor =
        cls.constructors.any((it) => it.isDefaultConstructor);
    check(hasDefaultConstructor || cls.isEnum,
        'Classes annotated with @HiveType must have a default constructor.');

    return cls;
  }

  Map<int, FieldElement> getFields(ClassElement cls) {
    var typeFields = <int, FieldElement>{};
    for (var field in cls.fields) {
      var fieldAnn = getHiveFieldAnn(field);
      if (fieldAnn == null) continue;

      var fieldNum = fieldAnn.index;
      check(fieldNum >= 0 || fieldNum <= 255,
          'Field numbers can only be in the range 0-255.');
      check(!typeFields.containsKey(fieldNum),
          'Duplicate field number: $fieldNum.');
      typeFields[fieldNum] = field;
    }
    return typeFields;
  }

  String getAdapterName(String typeName, ConstantReader annotation) {
    var annAdapterName = annotation.read('adapterName');
    if (annAdapterName.isNull) {
      return '${typeName}Adapter';
    } else {
      return annAdapterName.stringValue;
    }
  }
}
