import 'package:flutter/material.dart';
import 'package:todo/todo.dart';
import 'package:hive/hive.dart';

class TodoList extends StatelessWidget {
  final List<Todo> todos;

  TodoList(this.todos);

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return Center(
        child: Text('Noting to do... Great!'),
      );
    } else {
      return ListView.builder(
        itemCount: todos.length,
        itemBuilder: (BuildContext context, int index) {
          var todo = todos[index];
          return _buildTodo(todo);
        },
      );
    }
  }

  Widget _buildTodo(Todo todo) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  todo.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: todo.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  "${todo.created.hour}:${todo.created.minute}:${todo.created.second}",
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),
            Spacer(),
            IconButton(
              iconSize: 30,
              icon: Icon(todo.done ? Icons.clear : Icons.check),
              onPressed: () {
                var newTodo = todo.copyWith(done: !todo.done);
                Hive.box('todos').put(newTodo.id, newTodo);
              },
            ),
            IconButton(
              iconSize: 30,
              icon: Icon(Icons.delete),
              onPressed: () {
                Hive.box('todos').delete(todo.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
