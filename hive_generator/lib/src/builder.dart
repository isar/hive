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
  final List<AdapterField> getters;
  final List<AdapterField> setters;

  Builder(this.cls, this.getters, this.setters) : assert(cls != null);

  String buildRead();

  String buildWrite();
}
