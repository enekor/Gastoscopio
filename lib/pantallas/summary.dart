import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/widgets/views/summaryWidget.dart';
import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  Cuenta cuenta;
  SummaryPage({Key? key, required this.cuenta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
      },
      child: Scaffold(
          body: CustomPaint(
            painter: MyPattern(context),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(
                child: SingleChildScrollView(
                  child: summaryView(cuenta.Meses,context)
                ),
              ),
            )
          )
      ),
    );
  }
}