import 'package:hive/hive.dart';

part 'cat.g.dart';

@HiveType(typeId: 3)
class Animal {
  Animal({required this.field1, required this.field0});

  @HiveField(0)
  final String field0;

  @HiveField(1)
  final int field1;
}

@HiveType(typeId: 5)
class Cat extends Animal {
  Cat({
    required this.field2,
    required String field0,
    required int field1,
    String? foo,
  }) : super(field1: field1, field0: field0);

  @HiveField(2)
  final String field2;
}

@HiveType(typeId: 6)
class Tiger extends Cat {
  Tiger(
    this.field3, {
    required String field2,
    required String field0,
    required int field1,
    String? foo,
  }) : super(field0: field0, field1: field1, field2: field2);

  @HiveField(3)
  final int field3;
}
