import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:hive/hive.dart';
import 'package:hive_generator/src/builder.dart';
import 'package:hive_generator/src/class_builder.dart';
import 'package:hive_generator/src/enum_builder.dart';
import 'package:hive_generator/src/helper.dart';
import 'package:source_gen/source_gen.dart';

class TypeAdapterGenerator extends GeneratorForAnnotation<HiveType> {
  static String generateName(String typeName) {
    var adapterName =
        '${typeName}Adapter'.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '');
    if (adapterName.startsWith('_')) {
      adapterName = adapterName.substring(1);
    }
    if (adapterName.startsWith(r'$')) {
      adapterName = adapterName.substring(1);
    }
    return adapterName;
  }

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    var interface = getInterface(element);
    var library = await buildStep.inputLibrary;
    var gettersAndSetters = getAccessors(interface, library);

    var getters = gettersAndSetters[0];
    verifyFieldIndices(getters);

    var setters = gettersAndSetters[1];
    verifyFieldIndices(setters);

    var typeId = getTypeId(annotation);

    var adapterName = getAdapterName(interface.name, annotation);
    var builder = interface is EnumElement
        ? EnumBuilder(interface, getters)
        : ClassBuilder(interface, getters, setters);

    return '''
    class $adapterName extends TypeAdapter<${interface.name}> {
      @override
      final int typeId = $typeId;

      @override
      ${interface.name} read(BinaryReader reader) {
        ${builder.buildRead()}
      }

      @override
      void write(BinaryWriter writer, ${interface.name} obj) {
        ${builder.buildWrite()}
      }

      @override
      int get hashCode => typeId.hashCode;

      @override
      bool operator ==(Object other) =>
          identical(this, other) ||
          other is $adapterName &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
    }
    ''';
  }

  InterfaceElement getInterface(Element element) {
    check(element.kind == ElementKind.CLASS || element.kind == ElementKind.ENUM,
        'Only classes or enums are allowed to be annotated with @HiveType.');

    return element as InterfaceElement;
  }

  Set<String> getAllAccessorNames(InterfaceElement interface) {
    var accessorNames = <String>{};

    var supertypes = interface.allSupertypes.map((it) => it.element2);
    for (var type in [interface, ...supertypes]) {
      for (var accessor in type.accessors) {
        if (accessor.isSetter) {
          var name = accessor.name;
          accessorNames.add(name.substring(0, name.length - 1));
        } else {
          accessorNames.add(accessor.name);
        }
      }
    }

    return accessorNames;
  }

  List<List<AdapterField>> getAccessors(
      InterfaceElement interface, LibraryElement library) {
    var accessorNames = getAllAccessorNames(interface);

    var getters = <AdapterField>[];
    var setters = <AdapterField>[];
    for (var name in accessorNames) {
      var getter = interface.lookUpGetter(name, library);
      if (getter != null) {
        var getterAnn =
            getHiveFieldAnn(getter.variable) ?? getHiveFieldAnn(getter);
        if (getterAnn != null) {
          var field = getter.variable;
          getters.add(AdapterField(
            getterAnn.index,
            field.name,
            field.type,
            getterAnn.defaultValue,
          ));
        }
      }

      var setter = interface.lookUpSetter('$name=', library);
      if (setter != null) {
        var setterAnn =
            getHiveFieldAnn(setter.variable) ?? getHiveFieldAnn(setter);
        if (setterAnn != null) {
          var field = setter.variable;
          setters.add(AdapterField(
            setterAnn.index,
            field.name,
            field.type,
            setterAnn.defaultValue,
          ));
        }
      }
    }

    return [getters, setters];
  }

  void verifyFieldIndices(List<AdapterField> fields) {
    for (var field in fields) {
      check(field.index >= 0 && field.index <= 255,
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
    }
  }

  String getAdapterName(String typeName, ConstantReader annotation) {
    var annAdapterName = annotation.read('adapterName');
    if (annAdapterName.isNull) {
      return generateName(typeName);
    } else {
      return annAdapterName.stringValue;
    }
  }

  int getTypeId(ConstantReader annotation) {
    check(
      !annotation.read('typeId').isNull,
      'You have to provide a non-null typeId.',
    );
    return annotation.read('typeId').intValue;
  }
}
