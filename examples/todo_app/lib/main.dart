import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo_app/new_todo_dialog.dart';
import 'package:todo_app/todo.dart';
import 'package:todo_app/todo_list.dart';
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
                isBrowser
                    ? 'Refresh this tab to test persistence.'
                    : 'Restart the app to test persistence.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Expanded(
                child: WatchBoxBuilder(
                  box: Hive.box('todos'),
                  builder: (context, box) {
                    var todos = box.values.toList().cast<Todo>();
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
