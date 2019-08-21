import 'package:flutter/material.dart';
import 'package:todo_app/todo.dart';
import 'package:hive/hive.dart';

class NewTodoDialog extends StatefulWidget {
  @override
  _NewTodoDialogState createState() => _NewTodoDialogState();
}

class _NewTodoDialogState extends State<NewTodoDialog> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create To-Do Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              hintText: 'Enter a task',
            ),
            controller: controller,
          ),
          SizedBox(height: 10),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Add'),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              var todo = Todo()
                ..name = controller.text
                ..created = DateTime.now();
              Hive.box('todos').put(todo.id, todo);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
