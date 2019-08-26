import 'package:drawing_board/colored_point_adapter.dart';
import 'package:drawing_board/drawing_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'is_browser/vm.dart' if (dart.library.html) 'is_browser/js.dart';

void main() {
  runApp(DrawApp());
}

class DrawApp extends StatelessWidget {
  Future _openBox() async {
    if (!isBrowser) {
      var dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    }
    Hive.registerAdapter(ColoredPointAdapter(), 35);
    return await Hive.openBox('paths');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
              return DrawingScreen();
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
    );
  }
}
