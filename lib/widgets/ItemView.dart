import 'package:flutter/material.dart';

Widget ItemCard(String nombre,double ahorro) => SizedBox(
  height: 100,
  width: 100,
  child:   Card(
        child: Column(
          children: [
            const Icon(
              Icons.face,
              color: Colors.amber,
              size:50.0
            ),
            Text(nombre),
            Text("${ahorro.toStringAsFixed(2)}€")
          ],
        )
    ),
);

