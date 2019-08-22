import 'package:flutter/rendering.dart';

class DrawingPoint {
  Paint _paint;
  Paint get paint {
    _paint ??= Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = Color(colorValue)
      ..strokeWidth = 3;
    return _paint;
  }

  int colorValue;

  Offset point;
}
