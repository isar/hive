import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  String firstName;

  @HiveField(1)
  String lastName;

  @HiveField(2)
  DateTime birthday;
}

@HiveType(typeId: 2)
enum UserRole {
  @HiveField(0)
  customer,

  @HiveField(1)
  contentEditor,

  @HiveField(2)
  admin,
}
