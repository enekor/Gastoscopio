import 'dart:io';

import 'package:cuentas_android/utils/utils.dart';
import 'package:flutter/material.dart';

Widget CProgressIndicator() {
  return Center(
      child: Column(
    children: [
      AspectRatio(
          aspectRatio: 1.5, child: Image.asset(getImageUri(ImageUris.loading))),
      Text("Obteniendo datos...")
    ],
  ));
}
