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

void check(bool condition, dynamic error) {
  if (!condition) {
    throw error;
  }
}
