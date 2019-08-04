import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType()
class Task {
  @HiveField(0)
  String title;
  @HiveField(1)
  bool done;
  @HiveField(2)
  int id;

  Task({this.title, this.done});
}
