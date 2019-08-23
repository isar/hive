import 'package:drawing_app/colored_point.dart';
import 'package:flutter/rendering.dart';

class PathPainter extends CustomPainter {
  final List<ColoredPoint> pointsList;

  PathPainter(this.pointsList);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < pointsList.length - 1; i++) {
      canvas.drawLine(
        pointsList[i].offset,
        pointsList[i + 1].offset,
        pointsList[i].paint,
      );
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}
