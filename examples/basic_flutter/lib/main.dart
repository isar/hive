import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Demo',
      home: Scaffold(
        body: HiveBuilder.openBox(
          openBox: () async {
            var dir = await getApplicationDocumentsDirectory();
            Hive.init(dir.path);
            var box = await Hive.openBox('testBox');
            return box;
          },
          builder: _buildCounter,
          child: Center(
            child: Text('Please wait...'),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(context, box) {
    var number = box.get('number', defaultValue: 0);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'You have pushed the button $number times.',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: () {
                  box.put('number', number + 1);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Increase',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(width: 20),
              RaisedButton(
                onPressed: () {
                  box.put('number', 0);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Reset',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
