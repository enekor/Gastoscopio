import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils/utils.dart';
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
    required Function(Cuenta) onDelete}) {
  return Obx(
    () => SizedBox(
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
                      style: GoogleFonts.pacifico(
                          fontSize: 60, fontWeight: FontWeight.bold),
                      "Gastoscopio"),
                )),
            Expanded(
              flex: 6,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        orientation == Orientation.landscape ? 3 : 2,
                    crossAxisSpacing:
                        orientation == Orientation.landscape ? 50 : 5),
                shrinkWrap: true,
                padding: const EdgeInsets.all(20),
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
                    childHold: Container(
                      color: GetColor(ColorTypes.errorButton, context),
                      child: Icon(
                        Icons.delete_rounded,
                        color: GetColor(ColorTypes.text, context),
                      ),
                    ),
                    onPressOnHold: () =>
                        onDelete(Values().cuentas.value[index]),
                    context: context,
                  );
                },
              ),
            )
          ],
        )),
  );
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
