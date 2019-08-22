import 'dart:ui';

import 'package:drawing_app/drawing_area.dart';
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
                  builder: (context, box) {
                    return Stack(
                      children: <Widget>[
                        for (var points in box.values)
                          CustomPaint(
                            size: Size.infinite,
                            painter: DrawingPainter(
                              pointsList: (points as List).cast<DrawingPoint>(),
                            ),
                          ),
                      ],
                    );
                  },
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
                  for (var i = 0; i < drawingColors.length; i++)
                    buildColorCircle(i),
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      Hive.box('paths').clear();
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
          color: drawingColors[colorIndex],
        ),
      ),
    );
  }
}
