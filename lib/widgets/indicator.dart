import 'package:flutter/material.dart';

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.valor,
    required this.nombre,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String nombre;
  final String valor;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              color: color,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(nombre),
        ),
        Expanded(
          flex: 3,
          child: Text(valor),
        )
      ],
    );
  }
}
