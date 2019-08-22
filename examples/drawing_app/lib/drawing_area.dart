import 'package:drawing_app/drawing_painter.dart';
import 'package:drawing_app/drawing_point.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DrawingArea extends StatefulWidget {
  final int selectedColorIndex;

  DrawingArea(this.selectedColorIndex);

  @override
  _DrawingAreaState createState() => _DrawingAreaState();
}

class _DrawingAreaState extends State<DrawingArea> {
  var points = <DrawingPoint>[];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        addPoint(details.globalPosition);
      },
      onPanStart: (details) {
        addPoint(details.globalPosition);
      },
      onPanEnd: (details) {
        Hive.box('paths').add(points);
        setState(() {
          points = [];
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: DrawingPainter(
          pointsList: points,
        ),
      ),
    );
  }

  void addPoint(Offset point) {
    var renderBox = context.findRenderObject() as RenderBox;
    setState(() {
      points.add(
        DrawingPoint()
          ..colorIndex = widget.selectedColorIndex
          ..point = renderBox.globalToLocal(point),
      );
    });
  }
}
