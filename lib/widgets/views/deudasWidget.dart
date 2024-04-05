import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

AppBar appBar(){
  return AppBar();
}

Widget bodyHasDatos(){
  return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.personDigging,size: 100,),
          Text("Función aún en desarrollo")
        ],
      ),
  );
}