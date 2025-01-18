import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
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
  return Obx(() => orientation == Orientation.portrait
      ? SizedBox(
          height: height,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  flex: 4,
                  //child: Image.asset(getImageUri(ImageUris.logo)),
                  child: Center(
                    child: Column(
                      children: [
                        AspectRatio(
                            aspectRatio: 2,
                            child: Image.asset(getImageUri(ImageUris.logo))),
                        Text(
                            style: GoogleFonts.pacifico(
                                fontSize: 30, fontWeight: FontWeight.bold),
                            "Selecione un perfil"),
                      ],
                    ),
                  )),
              Expanded(
                  flex: 6,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: Values()
                        .cuentas
                        .value
                        .map((profile) => SizedBox(
                              width: 160,
                              height: 160,
                              child: CardButton(
                                color: HexColor(profile.color.value)
                                    .withOpacity(0.3),
                                onPressed: () => navigateInfo(profile),
                                child: Column(
                                  children: [
                                    SvgPicture.asset(
                                      height: 60,
                                      getImageUri(ImageUris.logosvg),
                                      color: HexColor(profile.color.value),
                                    ),
                                    Text(
                                      profile.Nombre.value,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${profile.Meses.value.last.GetAhorros().toStringAsFixed(2)}${Values().moneda.value}',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  ],
                                ),
                                childHold: Container(
                                  color:
                                      GetColor(ColorTypes.errorButton, context),
                                  child: Icon(
                                    Icons.delete_rounded,
                                    color: GetColor(ColorTypes.text, context),
                                  ),
                                ),
                                onPressOnHold: () => onDelete(profile),
                                context: context,
                              ),
                            ))
                        .toList(),
                  ))
            ],
          ))
      : Row(
          children: [
            Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    children: [
                      AspectRatio(
                          aspectRatio: 2,
                          child: Image.asset(getImageUri(ImageUris.logo))),
                      Text(
                          style: GoogleFonts.pacifico(
                              fontSize: 30, fontWeight: FontWeight.bold),
                          "Selecione un perfil"),
                    ],
                  ),
                )),
            Expanded(
                flex: 5,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: Values()
                      .cuentas
                      .value
                      .map((profile) => SizedBox(
                            width: 160,
                            height: 160,
                            child: CardButton(
                              color: HexColor(profile.color.value)
                                  .withOpacity(0.3),
                              onPressed: () => navigateInfo(profile),
                              child: Column(
                                children: [
                                  SvgPicture.asset(
                                    height: 60,
                                    getImageUri(ImageUris.logosvg),
                                    color: HexColor(profile.color.value),
                                  ),
                                  Text(
                                    profile.Nombre.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${profile.Meses.value.last.GetAhorros().toStringAsFixed(2)}${Values().moneda.value}',
                                    style: const TextStyle(fontSize: 12),
                                  )
                                ],
                              ),
                              childHold: Container(
                                color:
                                    GetColor(ColorTypes.errorButton, context),
                                child: Icon(
                                  Icons.delete_rounded,
                                  color: GetColor(ColorTypes.text, context),
                                ),
                              ),
                              onPressOnHold: () => onDelete(profile),
                              context: context,
                            ),
                          ))
                      .toList(),
                ))
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
