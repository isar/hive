import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const drawingColors = [
  Colors.black,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.amber,
];

final _paints = [
  Paint()
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..color = Colors.black
    ..strokeWidth = 3,
  Paint()
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..color = Colors.red
    ..strokeWidth = 3,
  Paint()
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..color = Colors.green
    ..strokeWidth = 3,
  Paint()
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..color = Colors.blue
    ..strokeWidth = 3,
  Paint()
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..color = Colors.amber
    ..strokeWidth = 3,
];

class DrawingPoint {
  Paint get paint => _paints[colorIndex];

  int colorIndex;

  Offset point;
}
