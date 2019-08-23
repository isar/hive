import 'dart:ui';

import 'package:drawing_app/clear_button.dart';
import 'package:drawing_app/colored_point.dart';
import 'package:drawing_app/drawing_area.dart';
import 'package:drawing_app/path_painter.dart';
import 'package:drawing_app/undo_button.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  var selectedColorIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                WatchBoxBuilder(
                  box: Hive.box('paths'),
                  builder: buildPathsFromBox,
                ),
                DrawingArea(selectedColorIndex),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < ColoredPoint.colors.length; i++)
                    buildColorCircle(i),
                  ClearButton(),
                  UndoButton(),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildPathsFromBox(BuildContext context, Box box) {
    return Stack(
      children: <Widget>[
        for (var path in box.values)
          CustomPaint(
            size: Size.infinite,
            painter: PathPainter((path as List).cast<ColoredPoint>()),
          ),
      ],
    );
  }

  Widget buildColorCircle(int colorIndex) {
    var selected = selectedColorIndex == colorIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColorIndex = colorIndex;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: selected ? 50 : 36,
          width: selected ? 50 : 36,
          color: ColoredPoint.colors[colorIndex],
        ),
      ),
    );
  }
}
