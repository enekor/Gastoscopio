import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';

Widget ItemCard(String nombre, double ahorro,
    {required Function open,
    required Function delete,
    required BuildContext context}) {
  RxBool seleccionado = false.obs;
  RxString text = nombre.obs;

  return Obx(
    () => Padding(
      padding: const EdgeInsets.only(left: 25, right: 25),
      child: GestureDetector(
        onLongPress:
            !kIsWeb ? () => seleccionado.value = !seleccionado.value : () {},
        onSecondaryTap:
            kIsWeb ? () => seleccionado.value = !seleccionado.value : () {},
        onTap: () => open(),
        child: Card(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.face,
              size: 50.0,
              color: Colors.black,
            ),
            Text(
              text.value,
            ),
            seleccionado.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        flex: 5,
                        child: IconButton(
                            onPressed: () {
                              seleccionado.value = false;
                              open();
                            },
                            icon: const Icon(Icons.open_in_new_rounded)),
                      ),
                      Expanded(
                        flex: 5,
                        child: IconButton(
                            onPressed: () {
                              seleccionado.value = false;
                              text.value = "Borrado";
                              delete();
                            },
                            icon: const Icon(Icons.delete)),
                      )
                    ],
                  )
                : SizedBox(
                    height: 0,
                  )
          ],
        )),
      ),
    ),
  );
}

Widget CardButton({required Function onPressed, required Widget child}) =>
    InkWell(
      onTap: () => onPressed(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );

Widget selectableSettingView<T>(
    {required String title,
    required List<T> values,
    required Function(T) onSelected,
    required double width}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(flex: 3, child: Text(title)),
      Expanded(
          flex: 7,
          child: DropdownButtonFormField(
            decoration: InputDecoration(
              constraints: BoxConstraints(maxWidth: width / 4),
            ),
            items: values
                .map((value) => DropdownMenuItem(
                      child: Text(value.toString()),
                      value: value,
                    ))
                .toList(),
            onChanged: (value) => onSelected(value!),
            value: values.first,
          ))
    ],
  );
}

Widget buttonSettingView(
    {required String text, IconData? icono, required Function onTap}) {
  return ElevatedButton(
    onPressed: () => onTap(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(text), icono != null ? Icon(icono) : Container()],
    ),
  );
}

Widget switchSettingView(
    {required Function(bool) onChange,
    required String text,
    required bool inicial}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(text), Switch(value: inicial, onChanged: onChange)],
  );
}

Widget redirectSettingView(
    {required Function onTap, required String text, Color? textColor}) {
  return TextButton(
    onPressed: () => onTap(),
    child: Text(
      text,
      style: textColor != null ? TextStyle(color: textColor) : TextStyle(),
    ),
  );
}

Widget textBoxSettingView(
    {required Function(String) onClick,
    required String title,
    String placeholder = ""}) {
  TextEditingController controller =
      TextEditingController(text: Values().moneda.value);

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(flex: 3, child: Text(title)),
      Expanded(
        flex: 3,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: placeholder,
          ),
        ),
      ),
      Expanded(
          flex: 3,
          child: IconButton(
              onPressed: () => onClick(controller.text),
              icon: const Icon(Icons.check)))
    ],
  );
}
