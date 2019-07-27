import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<Box> _openBox() async {
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    return await Hive.box('myBox');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<Box>(
          future: _openBox(),
          builder: (BuildContext context, AsyncSnapshot<Box> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return IceCreamPage();
            } else {
              return Center(
                child: Text('Please wait'),
              );
            }
          },
        ),
      ),
    );
  }
}

class IceCreamPage extends StatefulWidget {
  @override
  _IceCreamPageState createState() => _IceCreamPageState();
}

class _IceCreamPageState extends State<IceCreamPage> {
  var box = Hive['myBox'];

  @override
  void initState() {
    super.initState();

    box.watch().listen((e) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var userLikesIceCream = box['userLikesIceCream'] ?? false;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(userLikesIceCream
              ? 'You like ice cream'
              : 'You do not like ice cream. What is wrong with you?'),
          Checkbox(
            value: userLikesIceCream,
            onChanged: (selection) async {
              await box.put('userLikesIceCream', selection);
            },
          ),
        ],
      ),
    );
  }
}
