import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class MyPattern extends CustomPainter {
  late BuildContext context;
  MyPattern(this.context);

  final time = DateTime.now().millisecondsSinceEpoch;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();
    final paint = Paint();
    ThemeData theme = Theme.of(context);
    bool claro = theme.brightness == Brightness.dark;


    //circulo
    paint.color = claro?AppColorsL.secondaryColor1:AppColorsD.secondaryColor1;
    canvas.drawCircle(positions().posiciones[0], 100, paint);

    paint.color = claro?AppColorsL.secondaryColor2:AppColorsD.secondaryColor2;
    canvas.drawCircle(positions().posiciones[1], 75, paint);

    paint.color = claro?AppColorsL.secondaryColor3:AppColorsD.secondaryColor3;
    canvas.drawCircle(positions().posiciones[2], 50, paint);

    paint.color = claro?AppColorsL.secondaryColor4:AppColorsD.secondaryColor4;
    canvas.drawCircle(positions().posiciones[3], 40, paint);

    paint.color = claro?AppColorsL.secondaryColor5:AppColorsD.secondaryColor5;

//ola
    var sSize = MediaQuery.of(context).size;
    Path path = Path()..moveTo(0, sSize.height/2);
    path.moveTo(0, sSize.height * 0.7 );
    path.quadraticBezierTo(sSize.width * 0.25, sSize.height * 0.7 ,
        sSize.width * 0.5, sSize.height * 0.8);
    path.quadraticBezierTo(sSize.width * 0.75, sSize.height * 0.9 ,
        sSize.width * 1.0, sSize.height * 0.8);
    path.lineTo(sSize.width, sSize.height);
    path.lineTo(0, sSize.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

