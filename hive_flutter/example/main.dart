import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MyBoxWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HiveBuilder(
      boxName: 'TestBox',
      builder: (context, box) async {
        return Card(
          child: Column(
            children: <Widget>[
              Text(await box.get('title')),
              Spacer(),
              Text(await box.get('body')),
              Spacer(),
              Text(await box.get('footer')),
            ],
          ),
        );
      },
      loadingBuilder: (context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
