import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 1)
class Person extends HiveObject {
  @HiveField(0)
  String? firstName;

  @HiveField(1)
  String? lastName;

  @HiveField(2)
  DateTime? birthday;

  @HiveField(3)
  List<UserRole>? roles;

  @HiveField(4)
  HiveList<Person>? friends;
}

@HiveType(typeId: 2)
enum UserRole {
  @HiveField(0)
  customer,

  @HiveField(1, defaultValue: true)
  contentEditor,

  @HiveField(2)
  admin,
}
