import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo_app/todo.dart';
import 'is_browser/vm.dart' if (dart.library.html) 'is_browser/js.dart';

void main() {
  Hive.registerAdapter(TodoAdapter(), 35);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future _openBox() async {
    if (!isBrowser) {
      var dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    }
    return await Hive.openBox('todos');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive To-Do App',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'OpenSans'),
      home: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: FutureBuilder(
            future: _openBox(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                case ConnectionState.active:
                  return Scaffold(
                    body: Center(
                      child: Text('Opening Hive...'),
                    ),
                  );
                case ConnectionState.done:
                  if (snapshot.error != null) {
                    print(snapshot.error);
                    return Scaffold(
                      body: Center(
                        child: Text('Something went wrong :/'),
                      ),
                    );
                  } else {
                    return TodoMainScreen();
                  }
              }
            },
          ),
        ),
      ),
    );
  }
}

class TodoMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Hive To-Do App',
                style: TextStyle(fontSize: 40),
              ),
              SizedBox(height: 10),
              Text(
                'Refresh your tab or restart the app to test persistance.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Expanded(
                child: WatchBoxBuilder(
                  box: Hive.box('todos'),
                  builder: (context, box) {
                    var todos = List<Todo>();
                    for (var key in box.keys) {
                      var todo = (box.get(key) as Todo)..id = key as int;
                      todos.add(todo);
                    }
                    todos.sort((t1, t2) => t1.created.compareTo(t2.created));
                    return TodoList(todos);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return NewTodoDialog();
            },
          );
        },
      ),
    );
  }
}

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
                Hive.box('todos').put(todo.id, newTodo);
              },
            ),
            //SizedBox(width: 10),
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

class NewTodoDialog extends StatefulWidget {
  @override
  _NewTodoDialogState createState() => _NewTodoDialogState();
}

class _NewTodoDialogState extends State<NewTodoDialog> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: new Text('Create Todo Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              hintText: 'Enter a name',
            ),
            controller: controller,
          ),
          SizedBox(height: 10),
        ],
      ),
      actions: <Widget>[
        // usually buttons at the bottom of the dialog
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text("Add"),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              var todo = Todo()
                ..name = controller.text
                ..created = DateTime.now();
              Hive.box('todos').add(todo);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
