import 'package:drawing_app/drawing_point.dart';
import 'package:flutter/rendering.dart';

class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList});
  List<DrawingPoint> pointsList;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < pointsList.length - 1; i++) {
      canvas.drawLine(
        pointsList[i].point,
        pointsList[i + 1].point,
        pointsList[i].paint,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
