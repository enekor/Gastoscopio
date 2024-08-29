import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget hasData(
    {required BuildContext context,
    required Orientation orientation,
    required double width,
    required double height,
    required Function(Cuenta) navigateInfo,
    int? insertar,
    Cuenta? obj}) {
  if (insertar != null && insertar == 0) {
    Values().cuentas.value.removeWhere((element) => element == obj!);
    Values().cuentaRet.value = null;
  }

  if (insertar != null && insertar == 1) {
    Values().cuentas.value.addIf(!Values().cuentas.value.contains(obj!), obj);
  }
  return SizedBox(
      height: height,
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 4,
              //child: Image.asset(getImageUri(ImageUris.logo)),
              child: Center(
                child: Text(
                    style: GoogleFonts.pacifico(fontSize: 40, fontWeight: FontWeight.bold),
                    "Gastoscopio"),
              )),
          Expanded(
            flex: 6,
            child: Obx(
              () => GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        orientation == Orientation.landscape ? 3 : 2,
                    crossAxisSpacing:
                        orientation == Orientation.landscape ? 50 : 5),
                shrinkWrap: true,
                padding: EdgeInsets.all(20),
                itemCount: Values().cuentas.value.length,
                itemBuilder: (BuildContext context, int index) {
                  return CardButton(
                      onPressed: () =>
                          navigateInfo(Values().cuentas.value[index]),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 8,
                            child: SvgPicture.asset(
                              getImageUri(ImageUris.logosvg),
                              //theme: SvgTheme(currentColor: HexColor(Values().cuentas.value[index].color)),
                              color: HexColor(
                                  Values().cuentas.value[index].color.value),
                            ),
                          ),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  Values().cuentas.value[index].Nombre.value))
                        ],
                      ),
                      context: context);
                },
              ),
            ),
          )
        ],
      ));
}

AppBar appBar(
    {required Function onSettings,
    bool withName = true,
    required BuildContext context}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    title: const Text(""),
    actions: [
      IconButton(
          iconSize: 40,
          onPressed: () => onSettings(),
          icon: const Icon(Icons.settings))
    ],
  );
}
