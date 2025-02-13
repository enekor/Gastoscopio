import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

Widget CardButton(
    {required Function onPressed,
    void Function(dynamic)? onHold,
    dynamic item,
    required Widget child,
    double? topRight,
    double? topLeft,
    double? bottomRight,
    double? bottomLeft,
    double padding = 20,
    double margin = 10,
    Color? color,
    required BuildContext context,
    Widget? childHold,
    Function()? onPressOnHold}) {
  RxBool longPress = false.obs;

  return Builder(builder: (context) {
    return GestureDetector(
      onTap: () => onPressed(),
      onLongPressUp: onPressOnHold,
      onLongPress: onHold != null ? () => onHold(item) : () {},
      child: Obx(
        () => Card(
          margin: EdgeInsets.all(margin),
          color: color ?? Theme.of(context).colorScheme.surface,
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
                child: longPress.value
                    ? childHold != null
                        ? Column(
                            children: [
                              childHold,
                              ElevatedButton(
                                  onPressed: () => longPress.value = false,
                                  child: const Text("Cancelar"))
                            ],
                          )
                        : child
                    : child),
          ),
        ),
      ),
    );
  });
}

Widget ActionChipButton(
    {required String text,
    required Function() onPressed,
    required bool selected,
    Icon? icon}) {
  return Builder(builder: (context) {
    return ActionChip(
      avatar: icon,
      label: Text(text),
      onPressed: onPressed,
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : null, // null usará el color por defecto del tema
    );
  });
}

Widget selectableSettingView<T>(
    {required String title,
    required List<T> values,
    required Function(T) onSelected,
    required double width,
    T? initialValue}) {
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
                      value: value,
                      child: Text(value.toString()),
                    ))
                .toList(),
            onChanged: (value) => onSelected(value as T),
            value: initialValue ?? values.first,
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
      style:
          textColor != null ? TextStyle(color: textColor) : const TextStyle(),
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
          title: const Text('Seleccionar nuevo color'),
          content: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) => nuevo.value = color),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                onColorChanged();
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
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
                backgroundColor: WidgetStatePropertyAll(nuevo.value)),
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
  RxBool tapped = false.obs;

  return Obx(
    () => Padding(
      padding: const EdgeInsets.only(right: 15, left: 15, bottom: 5),
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
                  icon: AnimatedArrow(tapped.value),
                  onPressed: () => tapped.value = !tapped.value,
                ),
              )
            ],
          ),
          AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              height: tapped.value ? 60 : 0,
              width: tapped.value ? MediaQuery.of(context).size.width : 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Card(
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
                    gasto.tag.value != "" &&
                            Values()
                                .cuentaRet
                                .value!
                                .tags
                                .contains(gasto.tag.value)
                        ? gasto.tag.value
                        : "Sin tag asignado",
                  ),
                  IconButton(
                      onPressed: () => onTapEdit(gasto),
                      icon: const Icon(Icons.edit_rounded))
                ],
              )),
          const Divider()
        ],
      ),
    ),
  );
}

Widget MiniGastoView(
    {required double valor,
    required List<String> nombres,
    required Function(Gasto) onSave,
    required Function(Gasto) onDelete}) {
  RxBool editing = false.obs;
  TextEditingController nombre = TextEditingController();
  RxBool seleccionado = false.obs;
  RxBool customName = true.obs;
  String ddValue = nombres[0];

  Gasto createGasto() {
    seleccionado.value = !seleccionado.value;
    return Gasto(nombre: nombre.text.obs, valor: valor.obs);
  }

  return Obx(() => Card(
        color: seleccionado.value ? Colors.green.shade500 : Colors.grey,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Row(
                children: editing.value
                    ? [
                        Expanded(
                            flex: 3,
                            child: customName.value
                                ? TextField(
                                    controller: nombre,
                                    decoration: const InputDecoration(
                                        label: Text('Nombre')),
                                    onChanged: (value) {
                                      nombre.text = value;
                                    },
                                    textAlign: TextAlign.center)
                                : DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                    items: nombres.toSet().map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value.replaceAll('\n', ''),
                                        alignment: Alignment.center,
                                        child: Text(
                                          value.replaceAll('\n', ''),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      nombre.text =
                                          value?.replaceAll('\n', '') ?? "";
                                      ddValue = value!;
                                    },
                                    value: ddValue,
                                  )),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            decoration:
                                const InputDecoration(label: Text('Valor')),
                            textAlign: TextAlign.center,
                            initialValue: valor.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              valor = double.parse(value == '' ? '0' : value);
                            },
                          ),
                        ),
                        IconButton(
                            onPressed: () => editing.value = false,
                            icon: const Icon(Icons.save))
                      ]
                    : [
                        Expanded(
                            flex: 3,
                            child: Text(
                              nombre.text,
                              textAlign: TextAlign.center,
                            )),
                        Expanded(
                          flex: 3,
                          child: Text(
                            valor.toStringAsFixed(2),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                            onPressed: () => editing.value = true,
                            icon: const Icon(Icons.edit)),
                        seleccionado.value
                            ? IconButton(
                                icon: const Icon(Icons.cancel),
                                onPressed: () => onDelete(createGasto()),
                              )
                            : IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () => onSave(createGasto()),
                              )
                      ],
              ),
              editing.value
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Expanded(
                              flex: 5, child: Text('Texto de la imagen')),
                          Expanded(
                            flex: 5,
                            child: Switch(
                              value: customName.value,
                              onChanged: (value) => customName.value = value,
                            ),
                          ),
                        ],
                      ),
                    )
            ],
          ),
        ),
      ));
}

Widget LastInteractionGastoView({required Gasto gasto}) {
  return ListTile(
    title: Text(gasto.nombre.value),
    subtitle: Text(
        '${gasto.valor.value.toStringAsFixed(2)} ${Values().moneda.value}'),
    trailing: Text('${gasto.anno}/${gasto.mes.value}/${gasto.dia.value}'),
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

Widget ChangingPill(
    {required String text1,
    required String text2,
    required int selected,
    required Function onClick,
    required BuildContext context}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ActionChipButton(
          text: text1, onPressed: () => onClick(), selected: selected == 0),
      ActionChipButton(
          text: text2, onPressed: () => onClick(), selected: selected == 1)
    ],
  );
}

Widget HeadBox() {
  double height = AppBar().preferredSize.height;

  return SizedBox(height: height);
}

class AnimatedCard extends StatefulWidget {
  AnimatedCard(
      {required this.text,
      required this.icon,
      required this.children,
      super.key});
  String text;
  Icon icon;
  List<Widget> children;

  @override
  _AnimatedCardState createState() => _AnimatedCardState(text, icon, children);
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;
  String text;
  Icon icon;
  List<Widget> children;

  _AnimatedCardState(this.text, this.icon, this.children);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _animation,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
