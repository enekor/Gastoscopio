import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget newEditBodyVertical(
    {required String name,
    bool editar = false,
    required String valor,
    required DateTime fecha,
    required String tag,
    required Function(String) onChangeName,
    required Function(String) onChangeValue,
    required Function(DateTime) onDateSelected,
    required Function(String) onChangeTag,
    required Function(ShowingGastos) onChangeType,
    required ShowingGastos actualType,
    required BuildContext context}) {
  return Card(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(20),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(15)),
    margin: const EdgeInsets.all(15),
    child: Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            !editar ? _type(context, onChangeType) : Container(),
            const SizedBox(
              height: 10,
            ),
            _nameValue(
                context, name, valor, onChangeName, onChangeValue, editar),
            const SizedBox(
              height: 10,
            ),
            _dateTag(context, tag, fecha, onDateSelected, onChangeTag, editar)
          ],
        ),
      ),
    ),
  );
}

Widget _type(BuildContext context, Function(ShowingGastos) onChangeType) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
        children: ShowingGastos.values
            .toList()
            .map((tipo) => _showingGastoToElem(context, tipo))
            .toList()),
  );
}

Widget _showingGastoToElem(BuildContext context, ShowingGastos tipo) {
  return Obx(
    () => ActionChipButton(
        selected: Values().showing.value == tipo,
        text: tipo.toString().replaceAll("ShowingGastos.", ''),
        onPressed: () => Values().showing.value = tipo),
  );
}

Widget _nameValue(BuildContext context, String name, String value,
    Function(String) onName, Function(String) onValue, bool editar) {
  return AnimatedCard(
      text: 'Nombre y valor',
      icon: const Icon(Icons.abc),
      children: [
        Center(
          child: !editar
              ? SizedBox(
                  width: MediaQuery.of(context).size.width * (2 / 3),
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: TextEditingController(text: name),
                    onChanged: (value) {
                      onName(value);
                    },
                  ),
                )
              : Text(name),
        ),
        const SizedBox(
          height: 15,
        ),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * (2 / 3),
            child: TextField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  suffixIcon: Obx(() => Text(Values().moneda.value))),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: value),
              onChanged: (value) {
                onValue(value);
              },
            ),
          ),
        ),
      ]);
}

Rx<DateTime> _date = Rx<DateTime>(DateTime.now());
RxString _tag = RxString('');

Widget _dateTag(BuildContext context, String tag, DateTime date,
    Function(DateTime) onDate, Function(String) onTag, bool editar) {
  if (editar) {
    _date.value = date;
    _tag.value = tag;
  }
  return AnimatedCard(
    text: 'Fecha y tag',
    icon: const Icon(Icons.date_range),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: !editar
                ? () => showDatePicker(
                      context: context,
                      initialDate: _date.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      currentDate: DateTime.now(),
                      confirmText: 'Confirmar',
                      cancelText: 'Cancelar',
                    ).then((pickedDate) {
                      if (pickedDate != null && pickedDate != _date.value) {
                        onDate(pickedDate);
                        _date.value = pickedDate;
                      }
                    })
                : () {},
            child: Obx(() => Text(
                  '${_date.value.year}/${_date.value.month}/${_date.value.day}',
                )),
          ),
          Column(
            children: [
              Obx(() => ItemSelector(
                    onSelect: (tag) {
                      onTag(tag ?? '');
                      _tag.value = tag!;
                    },
                    items: Values().cuentaRet.value!.tags.value,
                    defaultValue: _tag.value,
                  )),
              ElevatedButton(
                onPressed: () => editValuePopup(context, (t) {
                  onTag(t);
                  Values().cuentaRet.value!.tags.value.add(t);
                  _tag.value = t;
                }, _tag.value),
                child: const Text('Nuevo tag'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void editValuePopup(
    BuildContext context, Function(String) onEdit, String initialValue,
    {TextInputType keyboardType = TextInputType.text}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      TextEditingController controller =
          TextEditingController(text: initialValue);
      return AlertDialog(
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Terminar'),
            onPressed: () {
              onEdit(controller.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget gastoBottomNavigationBar(
    Function onSave, Function onCancel, BuildContext context) {
  return SizedBox(
    height: kBottomNavigationBarHeight,
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      ElevatedButton(
        onPressed: () => onSave(),
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.secondary.withAlpha(20)),
            surfaceTintColor: WidgetStateProperty.all(Colors.black)),
        child: const Text(
          'Guardar',
        ),
      ),
      ElevatedButton(
          onPressed: () => onCancel(),
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.error.withAlpha(50)),
              surfaceTintColor: WidgetStateProperty.all(Colors.black)),
          child: const Text(
            'Cancel',
            style: TextStyle(),
          ))
    ]),
  );
}
