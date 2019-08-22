import 'package:drawing_app/drawing_point.dart';
import 'package:flutter/rendering.dart';

class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList});
  List<DrawingPoint> pointsList;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < pointsList.length - 1; i++) {
      var point = pointsList[i];
      var nextPoint = pointsList[i + 1];
      if (point != null && pointsList[i + 1] != null) {
        canvas.drawLine(point.point, nextPoint.point, point.paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
