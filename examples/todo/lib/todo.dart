import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType()
class Todo {
  // We use the negative time as key in Hive to sort in descending order.
  int get id => -created.millisecondsSinceEpoch;

  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime created;

  @HiveField(2)
  bool done = false;

  Todo copyWith({bool done}) {
    return Todo()
      ..name = name
      ..created = created
      ..done = done;
  }
}
