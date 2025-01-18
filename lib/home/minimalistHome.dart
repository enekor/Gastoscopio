import 'dart:ui';

import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/home/home/homeWidgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget MinimalistHome(
    {required Function(int) onOption,
    required Function() onMoreDetails,
    required Function() onSettings,
    required Function() onNew}) {
  return OrientationBuilder(
    builder: (context,orientation)=>Obx(
          () => Padding(
            padding: const EdgeInsets.all(21.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                _greetingPart(),
                const SizedBox(
                  height: 10,
                ),
                _buildMainImage(
                    context, orientation, onOption, onSettings, onNew),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildDetailsButton(context, onMoreDetails),
                ),
              ],
            ),
          ),
    )
  );
}

Widget _greetingPart() {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MinimalistGreetingText(),
        const SizedBox(height: 8.0),
        MinimalistTotalPart(),
      ],
    ),
  );
}

Widget _buildMainImage(BuildContext context, Orientation orientation,
    Function(int) onOption, Function() onSettings, Function() onNew) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          _buildIconButton(
              Icons.attach_money, context, onOption, onSettings, onNew),
          _buildIconButton(Icons.add, context, onOption, onSettings, onNew),
          _buildIconButton(
              Icons.pie_chart, context, onOption, onSettings, onNew),
          _buildIconButton(
              Icons.calculate, context, onOption, onSettings, onNew),
          _buildIconButton(Icons.settings, context, onOption, onSettings, onNew)
        ],
      ),
    ),
  );
}

Widget _buildIconButton(IconData icon, BuildContext context,
    Function(int) onOption, Function() onSettings, Function() onNew) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: InkWell(
      onTap: () {
        _handleButtonTap(icon, context, onOption, onSettings, onNew);
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GetColor(ColorTypes.secondary, context),
        ),
        child: Icon(icon, size: 30, color: Colors.black87),
      ),
    ),
  );
}

void _handleButtonTap(IconData icon, BuildContext context,
    Function(int) onOption, Function() onSettings, Function() onNew) {
  String message;
  switch (icon) {
    case Icons.attach_money:
      onOption(1);
      break;
    case Icons.pie_chart:
      onOption(3);
      break;
    case Icons.add:
      onNew();
      break;
    case Icons.calculate:
      onOption(4);
      break;
    case Icons.settings:
      onSettings();
      break;
    default:
      message = '';
  }
}

Widget _buildDetailsButton(BuildContext context, Function() onMoreDetails) {
  return TextButton(
      onPressed: onMoreDetails, child: const Text("Mas detalles"));
}

// Suggested code may be subject to a license. Learn more: ~LicenseLog:1601473123.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1140774953.

   
