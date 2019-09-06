import 'package:analyzer/dart/element/element.dart';

abstract class Builder {
  final ClassElement cls;
  final Map<int, FieldElement> fields;

  Builder(this.cls, this.fields)
      : assert(cls != null),
        assert(fields != null);

  String buildRead();

  String buildWrite();
}
