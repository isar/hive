import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UndoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WatchBoxBuilder(
      box: Hive.box('sketch'),
      builder: (context, box) {
        return IconButton(
          icon: Icon(Icons.undo),
          onPressed: box.length == 0
              ? null
              : () {
                  box.deleteAt(box.length - 1);
                },
        );
      },
    );
  }
}
