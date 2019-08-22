import 'dart:ui';

import 'package:drawing_app/drawing_painter.dart';
import 'package:drawing_app/drawing_point.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DrawScreen extends StatefulWidget {
  @override
  _DrawScreenState createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  Color selectedColor = Colors.black;
  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.amber,
    Colors.black
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: WatchBoxBuilder(
              box: Hive.box('points'),
              builder: buildDrawingArea,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (Color color in colors) buildColorCircle(color),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      Hive.box('points').clear();
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildDrawingArea(BuildContext context, Box box) {
    void addPoint(Offset point) {
      var renderBox = context.findRenderObject() as RenderBox;
      box.add(
        DrawingPoint()
          ..colorValue = selectedColor.value
          ..point = renderBox.globalToLocal(point),
      );
    }

    return GestureDetector(
      onPanUpdate: (details) {
        addPoint(details.globalPosition);
      },
      onPanStart: (details) {
        addPoint(details.globalPosition);
      },
      onPanEnd: (details) {
        setState(() {
          box.add(null);
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: DrawingPainter(
          pointsList: box.values.cast<DrawingPoint>().toList(),
        ),
      ),
    );
  }

  Widget buildColorCircle(Color color) {
    var selected = selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          height: selected ? 50 : 36,
          width: selected ? 50 : 36,
          color: color,
        ),
      ),
    );
  }
}
