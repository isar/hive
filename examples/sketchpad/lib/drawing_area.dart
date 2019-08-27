import 'package:sketchpad/colored_path.dart';
import 'package:sketchpad/path_painter.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DrawingArea extends StatefulWidget {
  final int selectedColorIndex;

  DrawingArea(this.selectedColorIndex);

  @override
  _DrawingAreaState createState() => _DrawingAreaState();
}

class _DrawingAreaState extends State<DrawingArea> {
  var path = ColoredPath(0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        addPoint(details.globalPosition);
      },
      onPanStart: (details) {
        path = ColoredPath(widget.selectedColorIndex);
        addPoint(details.globalPosition);
      },
      onPanEnd: (details) {
        Hive.box('paths').add(path);
        setState(() {
          path = ColoredPath(0);
        });
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: PathPainter(path),
      ),
    );
  }

  void addPoint(Offset point) {
    var renderBox = context.findRenderObject() as RenderBox;
    setState(() {
      path.addPoint(renderBox.globalToLocal(point));
    });
  }
}
