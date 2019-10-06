import 'package:analyzer/dart/element/element.dart';
import 'package:hive/hive.dart';
import 'package:source_gen/source_gen.dart';

final _hiveTypeChecker = const TypeChecker.fromRuntime(HiveType);
final _hiveFieldChecker = const TypeChecker.fromRuntime(HiveField);

HiveType getHiveTypeAnn(Element element) {
  var obj = _hiveTypeChecker.firstAnnotationOfExact(element);
  if (obj == null) return null;
  return HiveType(
    adapterName: obj.getField('adapterName').toStringValue(),
  );
}

HiveField getHiveFieldAnn(Element element) {
  var obj = _hiveFieldChecker.firstAnnotationOfExact(element);
  if (obj == null) return null;
  return HiveField(
    obj.getField('index').toIntValue(),
  );
}

Iterable<ClassElement> getTypeAndAllSupertypes(ClassElement cls) {
  var types = <ClassElement>{};
  types.add(cls);
  types.addAll(cls.allSupertypes.map((it) => it.element));
  return types;
}

void check(bool condition, dynamic error) {
  if (!condition) {
    throw error;
  }
}
