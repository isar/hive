import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todo/new_todo_dialog.dart';
import 'package:todo/todo.dart';
import 'package:todo/todo_list.dart';
import 'is_browser/vm.dart' if (dart.library.html) 'is_browser/js.dart';

void main() {
  Hive.registerAdapter(TodoAdapter(), 35);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future _openBoxes() async {
    if (!isBrowser) {
      var dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    }
    return Future.wait([
      Hive.openBox('settings'),
      Hive.openBox('todos'),
    ]);
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
            future: _openBoxes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
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
              } else {
                return Scaffold(
                  body: Center(
                    child: Text('Opening Hive...'),
                  ),
                );
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
          child: WatchBoxBuilder(
            box: Hive.box('settings'),
            builder: _buildWithBox,
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

  Widget _buildWithBox(BuildContext context, Box settings) {
    var reversed = settings.get('reversed', defaultValue: true) as bool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Hive To-Do',
              style: TextStyle(fontSize: 40),
            ),
            SizedBox(width: 20),
            IconButton(
              icon: Icon(
                reversed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 32,
              ),
              onPressed: () {
                settings.put('reversed', !reversed);
              },
            ),
          ],
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
              if (reversed) {
                todos = todos.reversed.toList();
              }
              return TodoList(todos);
            },
          ),
        ),
      ],
    );
  }
}
