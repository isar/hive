import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

class AdapterField {
  final int index;
  final PropertyAccessorElement element;

  String get name => element.variable.name;
  DartType get type => element.variable.type;

  bool get isNullable {
    switch (element.variable.type?.nullabilitySuffix) {
      case NullabilitySuffix.none:
        return false;
      default:
        return true;
    }
  }

  AdapterField(this.index, this.element);
  BuiltAdapterField toBuilt(bool nestedBuilders) => BuiltAdapterField(
        index,
        element,
        nestedBuilders,
      );
}

class BuiltAdapterField extends AdapterField {
  DartType _type;

  @override
  DartType get type => _type ?? super.type;
  set type(DartType type) => _type = type;

  bool nestedBuilders;

  BuiltAdapterField(
    int index,
    PropertyAccessorElement element,
    this.nestedBuilders,
  ) : super(index, element);

  bool get hasNullableAnnotation => element.metadata.any((metadata) =>
      metadata.computeConstantValue()?.toStringValue() == 'nullable');

  bool get hasNullableType =>
      element?.returnType?.nullabilitySuffix == NullabilitySuffix.question;

  @override
  bool get isNullable => hasNullableAnnotation || hasNullableType;

  @override
  BuiltAdapterField toBuilt(bool nestedBuilders) =>
      throw StateError('Already is an BuiltAdapterField');
}

abstract class Builder {
  final ClassElement cls;
  final List<AdapterField> getters;
  final List<AdapterField> setters;

  Builder(this.cls, this.getters, this.setters) : assert(cls != null);

  String buildRead();

  String buildWrite();
}
