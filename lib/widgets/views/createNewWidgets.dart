import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

RxString tag = "".obs;
Rx<DateTime?> _fechaNueva = DateTime.now().obs;

AppBar CreateNewAppBar() => AppBar(
      backgroundColor: Colors.transparent,
      title: const Center(
        child: Text("Nuevo gasto"),
      ),
    );

Widget TopPart() => Obx(() => Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Text(
        Values().editing.value ? "Editar existente" : "Crear nuevo",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        textAlign: TextAlign.center,
      ),
    ));

Widget typePart(BuildContext context) {
  return Obx(() => Values().editing.value == false
      ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              CardButton(
                  onPressed: () =>
                      Values().showing.value = ShowingGastos.gastos,
                  child: const Text('Gasto'),
                  context: context,
                  padding:
                      Values().showing.value == ShowingGastos.gastos ? 10 : 8,
                  margin: 8,
                  color: Values().showing.value == ShowingGastos.gastos
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.secondary, context)),
              CardButton(
                  onPressed: () =>
                      Values().showing.value = ShowingGastos.extras,
                  child: const Text('Extra'),
                  context: context,
                  padding:
                      Values().showing.value == ShowingGastos.extras ? 10 : 8,
                  margin: 8,
                  color: Values().showing.value == ShowingGastos.extras
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.secondary, context)),
              CardButton(
                  onPressed: () => Values().showing.value = ShowingGastos.fijo,
                  child: const Text('Periódico'),
                  context: context,
                  padding:
                      Values().showing.value == ShowingGastos.fijo ? 10 : 8,
                  margin: 8,
                  color: Values().showing.value == ShowingGastos.fijo
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.secondary, context)),
              CardButton(
                  onPressed: () =>
                      Values().showing.value = ShowingGastos.ingresos,
                  child: const Text('Ingreso'),
                  context: context,
                  padding:
                      Values().showing.value == ShowingGastos.ingresos ? 10 : 8,
                  margin: 8,
                  color: Values().showing.value == ShowingGastos.ingresos
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.secondary, context)),
              CardButton(
                  onPressed: () => Values().showing.value = ShowingGastos.deuda,
                  child: const Text('Deuda'),
                  context: context,
                  padding:
                      Values().showing.value == ShowingGastos.deuda ? 10 : 8,
                  margin: 8,
                  color: Values().showing.value == ShowingGastos.deuda
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.secondary, context)),
            ],
          ),
        )
      : Container());
}

Widget formPart(
    {required List<String> tags,
    required BuildContext context,
    required void Function() onNewTag,
    required void Function() onDate,
    required TextEditingController nombre,
    required TextEditingController valor,
    required bool isLandscape}) {
  return Obx(
    () => Card.filled(
      margin: const EdgeInsets.all(10),
      color: GetColor(ColorTypes.primary, context).withOpacity(0.94),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              typePart(context),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Values().editing.value == false
                    ? TextField(
                        controller: nombre,
                        decoration:
                            const InputDecoration(label: Text('Nombre')),
                      )
                    : Text(nombre.text),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: valor,
                  decoration: InputDecoration(
                      label: const Text('Valor'),
                      suffix: Text(
                        Values().moneda.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      )),
                ),
              ),
              tagCreator(onCreateTag: () => onNewTag(), tags: tags),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CardButton(
                    onPressed: Values().editing.value == false ? onDate : () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_rounded),
                        Text(
                            '${_fechaNueva.value!.day}/${_fechaNueva.value!.month}/${_fechaNueva.value!.year}')
                      ],
                    ),
                    context: context),
              )
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buttonsPart(
    {required Function(String, double, String, DateTime, bool) onSave,
    required Function onCancel,
    required BuildContext context,
    required TextEditingController nombre,
    required TextEditingController valor}) {
  return Row(
    children: [
      Expanded(
        flex: 5,
        child: CardButton(
            onPressed: onCancel,
            child: const Text("Cancelar"),
            context: context,
            color: GetColor(ColorTypes.errorButton, context),
            padding: 15),
      ),
      Expanded(
        flex: 5,
        child: CardButton(
            onPressed: () => onSave(nombre.text, double.parse(valor.text),
                tag.value, _fechaNueva.value!, Values().editing.value),
            child: const Text("Guardar"),
            context: context,
            color: GetColor(ColorTypes.primary, context),
            padding: 15),
      ),
    ],
  );
}

Widget createNewHasData(
    {required Function(String, double, String, DateTime, bool) onSave,
    required Function onCancel,
    required BuildContext context,
    required void Function() onNewTag,
    required List<String> tags,
    required TextEditingController nombre,
    required TextEditingController valor,
    required DateTime fecha,
    required bool isLandscape}) {
  _fechaNueva.value = fecha;
  return Column(
    children: [
      TopPart(),
      formPart(
          tags: tags,
          context: context,
          onDate: () => onDate(context),
          onNewTag: onNewTag,
          nombre: nombre,
          valor: valor,
          isLandscape: isLandscape),
      const Spacer(),
      buttonsPart(
          onSave: onSave,
          onCancel: onCancel,
          context: context,
          nombre: nombre,
          valor: valor)
    ],
  );
}

Widget tagCreator(
    {required void Function() onCreateTag, required List<String> tags}) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        tags.isNotEmpty
            ? ItemSelector(
                onSelect: (t) => tag.value = t!,
                items: tags,
                defaultValue: tag.value)
            : Container(),
        ElevatedButton(onPressed: onCreateTag, child: const Text("Crear tag")),
      ],
    ),
  );
}

Future<void> onDate(BuildContext context) async {
  _fechaNueva.value = await showDatePicker(
    context: context,
    initialDate: _fechaNueva
        .value, // Fecha inicial (si ya se seleccionó una fecha previamente, se muestra esa)
    firstDate: DateTime(2000), // Fecha mínima
    lastDate: DateTime(2101), // Fecha máxima
  );
}
