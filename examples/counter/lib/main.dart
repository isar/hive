import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'is_browser/vm.dart' if (dart.library.html) 'is_browser/js.dart';

void main() => runApp(MyApp());

Future _openBox() async {
  if (!isBrowser) {
    var dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }
  return await Hive.openBox('myBox');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'OpenSans',
      ),
      home: FutureBuilder(
        future: _openBox(),
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
              return MyHomePage(title: 'Hive Demo Page');
            }
          } else {
            return Scaffold();
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Box _box;

  @override
  void initState() {
    _box = Hive.box('myBox');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have pushed the button this many times:'),
            WatchBoxBuilder(
              box: _box,
              builder: (context, box) {
                return Text(
                  box.get('counter', defaultValue: 0).toString(),
                  style: Theme.of(context).textTheme.display1,
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _box.put('counter', _box.get('counter', defaultValue: 0) + 1);
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
