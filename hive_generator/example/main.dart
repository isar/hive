import 'package:hive/hive.dart';

@HiveType()
class Person {
  @HiveField(1)
  String name;

  @HiveField(2)
  int age;

  @HiveField(3)
  int _income;

  @HiveField(4)
  List<String> hobbies;

  @HiveField(5)
  List<Person> friends;
}
