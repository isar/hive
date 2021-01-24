import 'package:analyzer/dart/element/element.dart';
import 'package:hive/hive.dart';
import 'package:source_gen/source_gen.dart';

final _hiveFieldChecker = const TypeChecker.fromRuntime(HiveField);

HiveField getHiveFieldAnn(Element element) {
  var obj = _hiveFieldChecker.firstAnnotationOfExact(element);
  if (obj == null) return null;
  return HiveField(
    obj.getField('index').toIntValue(),
  );
}

bool isLibraryNNBD(Element element) {
  final dartVersion = element.library.languageVersion.effective;
  // Libraries with the dart version >= 2.12 are nnbd
  if (dartVersion.major >= 2 && dartVersion.minor >= 12) {
    return true;
  } else {
    return false;
  }
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
