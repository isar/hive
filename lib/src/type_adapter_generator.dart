import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:hive_generator/src/builder.dart';
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
    var adapterName = getAdapterName(cls.name, annotation);
    var builder =
        cls.isEnum ? EnumBuilder(cls, fields) : ClassBuilder(cls, fields);

    return '''
    class $adapterName extends TypeAdapter<${cls.name}> {
      @override
      ${cls.name} read(BinaryReader reader) {
        ${builder.buildRead()}
      }

      @override
      void write(BinaryWriter writer, ${cls.name} obj) {
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

    return cls;
  }

  Iterable<AdapterField> getAccessors(ClassElement cls) {
    var fields = <AdapterField>[];
    for (var field in cls.fields) {
      var fieldAnn = getHiveFieldAnn(field);
      if (fieldAnn == null) continue;

      fields.add(AdapterField(fieldAnn.index, field.name, field.type));
    }

    for (var field in cls.accessors) {
      var fieldAnn = getHiveFieldAnn(field);
      if (fieldAnn == null || !field.isGetter) continue;

      fields.add(AdapterField(fieldAnn.index, field.name, field.type));
    }

    return fields;
  }

  List<AdapterField> getFields(ClassElement cls) {
    var types =
        getTypeAndAllSupertypes(cls).where((it) => getHiveTypeAnn(it) != null);
    for (var type in types) {
      print('TYPE: $type');
    }
    var adapterFields = <AdapterField>[];
    for (var type in types) {
      var fields = getAccessors(type);
      for (var field in fields) {
        print(field.name);
        check(field.index >= 0 || field.index <= 255,
            'Field numbers can only be in the range 0-255.');

        for (var otherField in fields) {
          if (otherField == field) continue;
          if (otherField.index == field.index) {
            throw HiveError(
              'Duplicate field number: ${field.index}. Fields "${field.name}" '
              'and "${otherField.name}" have the same number.',
            );
          }
        }

        adapterFields.add(field);
      }
    }
    return adapterFields;
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
