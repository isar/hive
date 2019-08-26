import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ColoredPoint {
  static const colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.amber,
  ];

  static List<Paint> _paints;

  Paint get paint {
    if (_paints == null) {
      _paints = [];
      for (var color in colors) {
        _paints.add(Paint()
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = color
          ..strokeWidth = 3);
      }
    }
    return _paints[colorIndex];
  }

  int colorIndex;

  Offset offset;
}
