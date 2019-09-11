import 'package:sketchpad/colored_path.dart';
import 'package:flutter/rendering.dart';

class PathPainter extends CustomPainter {
  final ColoredPath path;

  PathPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path.path, path.paint);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}
