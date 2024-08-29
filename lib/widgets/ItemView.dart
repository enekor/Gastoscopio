import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

Widget CardButton(
        {required Function onPressed,
        void Function(dynamic)? onHold,
        dynamic? item,
        required Widget child,
        double? topRight,
        double? topLeft,
        double? bottomRight,
        double? bottomLeft,
        double padding = 20,
        double margin = 10,
        Color? color,
        required BuildContext context}) =>
    GestureDetector(
      onTap: () => onPressed(),
      onLongPress: onHold != null ? () => onHold(item) : () {},
      child: Card(
        margin: EdgeInsets.all(margin),
        color: color ?? GetColor(ColorTypes.secondary, context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topLeft ?? 10),
            topRight: Radius.circular(topRight ?? 10),
            bottomLeft: Radius.circular(bottomLeft ?? 10),
            bottomRight: Radius.circular(bottomRight ?? 10),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Center(
            child: child,
          ),
        ),
      ),
    );

Widget ActionChipButton(
    {required Widget text,
    Function? onPressed,
    required Color color,
    Icon? icon}) {
  return Padding(
    padding: const EdgeInsets.only(right: 2.0, left: 2),
    child: ActionChip(
        label: text,
        onPressed: onPressed != null ? () => onPressed() : () {},
        backgroundColor: color,
        padding: EdgeInsets.all(5),
        avatar: icon),
  );
}

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

Widget colorPickerView(
    {required Function(String) onChange,
    required String text,
    required Color initialColor,
    required BuildContext context}) {
  Rx<Color> nuevo = initialColor.obs;
  void onColorChanged() {
    String colorHex = '#${nuevo.value.value.toRadixString(16).padLeft(8, '0')}';
    onChange(colorHex);
  }

  void openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleccionar nuevo color'),
          content: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) => nuevo.value = color),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                onColorChanged();
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(text),
      Obx(
        () => ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(nuevo.value)),
            onPressed: openColorPicker,
            child: const Text(
              "Cambiar color",
            )),
      )
    ],
  );
}

Widget ItemSelector(
    {required void Function(String?) onSelect,
    required List<String> items,
    required String defaultValue}) {
  return DropdownButton<String>(
    value: defaultValue,
    onChanged: onSelect,
    items: items.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value.isEmpty ? "Seleccionar" : value),
      );
    }).toList(),
  );
}

Widget gastoView(
    {required Gasto gasto,
    required void Function(Gasto) onTapEdit,
    required BuildContext context}) {
  RxBool _tapped = false.obs;

  return Obx(
    () => Padding(
      padding: EdgeInsets.only(right: 15, left: 15, bottom: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Center(child: Text(gasto.nombre.value)),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                      '${gasto.valor.value.toStringAsFixed(2)}${Values().moneda.value}'),
                ),
              ),
              Expanded(
                flex: 1,
                child: IconButton(
                  icon: AnimatedArrow(_tapped.value),
                  onPressed: () => _tapped.value = !_tapped.value,
                ),
              )
            ],
          ),
          AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              height: _tapped.value ? 60 : 0,
              width: _tapped.value ? MediaQuery.of(context).size.width : 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Card(
                    color: GetColor(ColorTypes.secondary, context),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month_rounded),
                          Text(
                            '${gasto.dia.value}/${gasto.mes.value}/${gasto.anno.value}',
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    ),
                  ),
                  Text(
                    gasto.tag.value != ""
                        ? gasto.tag.value
                        : "Sin tag asignado",
                    style: TextStyle(
                        color: GetColor(ColorTypes.secondary, context)),
                  ),
                  IconButton(
                      color: GetColor(ColorTypes.secondary, context),
                      onPressed: () => onTapEdit(gasto),
                      icon: const Icon(Icons.edit_rounded))
                ],
              )),
          Divider()
        ],
      ),
    ),
  );
}

Widget AnimatedArrow(bool abajo) {
  return AnimatedRotation(
    duration: const Duration(milliseconds: 150),
    curve: Curves.easeInOut,
    turns: abajo ? 0.5 : 0,
    child: const Icon(Icons.arrow_drop_down_circle_rounded, size: 24),
  );
}
