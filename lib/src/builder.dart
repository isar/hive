import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class AdapterField {
  final int index;
  final String name;
  final DartType type;

  AdapterField(this.index, this.name, this.type);
}

abstract class Builder {
  final ClassElement cls;
  final List<AdapterField> fields;

  Builder(this.cls, this.fields)
      : assert(cls != null),
        assert(fields != null);

  String buildRead();

  String buildWrite();
}
