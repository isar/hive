import 'package:drawing_board/colored_point.dart';
import 'package:drawing_board/path_painter.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DrawingArea extends StatefulWidget {
  final int selectedColorIndex;

  DrawingArea(this.selectedColorIndex);

  @override
  _DrawingAreaState createState() => _DrawingAreaState();
}

class _DrawingAreaState extends State<DrawingArea> {
  var points = <ColoredPoint>[];

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
        painter: PathPainter(points),
      ),
    );
  }

  void addPoint(Offset point) {
    var renderBox = context.findRenderObject() as RenderBox;
    setState(() {
      points.add(
        ColoredPoint()
          ..colorIndex = widget.selectedColorIndex
          ..offset = renderBox.globalToLocal(point),
      );
    });
  }
}
