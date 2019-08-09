import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' as prefix0;

abstract class Builder {
  final String cls;
  final Map<int, FieldElement> fields;

  Builder(this.cls, this.fields);

  String buildRead();

  String buildWrite();
}
