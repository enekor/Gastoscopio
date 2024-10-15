import 'dart:io';

import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils/ImageTextDetector.dart';
import 'package:cuentas_android/widgets/CProgressIndicator.dart';
import 'package:cuentas_android/widgets/views/GastosFromImageWidgets.dart';
import 'package:flutter/material.dart';

class GastosfromImage extends StatelessWidget {
  GastosfromImage({Key? key, required this.image}) : super(key: key);
  final List<Gasto> _toAdd = [];

  void onAddRemove(Gasto gasto) {
    if (_toAdd.contains(gasto)) {
      _toAdd.remove(gasto);
    } else {
      _toAdd.add(gasto);
    }
  }

  File image;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _toAdd);
          return false;
        },
        child: Scaffold(
            body: FutureBuilder<Map<List<String>, List<double>>>(
          future: extractInformationFromImage(image),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CProgressIndicator());
            } else if (snapshot.hasData) {
              return ImageHasData(
                  datos: snapshot.data!,
                  context: context,
                  onAddRemove: onAddRemove);
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return Text('No se que ha pasado');
            }
          },
        )));
  }
}
