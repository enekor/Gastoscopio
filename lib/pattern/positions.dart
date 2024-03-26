import 'package:flutter/material.dart';
import 'dart:math' as math;

class positions{
  static final positions _apiInstace = positions._internal();

  factory positions() {
    return _apiInstace;
  }
  positions._internal();

  List<Offset> posiciones = [];

  void ChangePositions(double width, double height) => posiciones = [
    Offset(math.Random().nextDouble()*width, math.Random().nextDouble()*height),
    Offset(math.Random().nextDouble()*width, math.Random().nextDouble()*height),
    Offset(math.Random().nextDouble()*width, math.Random().nextDouble()*height),
    Offset(math.Random().nextDouble()*width, math.Random().nextDouble()*height),
  ];
}