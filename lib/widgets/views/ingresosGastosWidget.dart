import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get/get.dart';

TextEditingController _nombreNuevo = TextEditingController();
TextEditingController _valorNuevo = TextEditingController();
TextEditingController _ingresoNuevo = TextEditingController();
RxBool _isIngresoSeleccionado = false.obs;

String valorTotal(
    bool isIngreso, double gastos, double extras, double ingresos) {
  return isIngreso
      ? (-1 * gastos + ingresos).toStringAsFixed(2)
      : (gastos + extras).toStringAsFixed(2);
}

AppBar appBar(
    {required List<Gasto> datos,
    required List<Gasto> extras,
    required bool isIngreso,
    required double ingreso,
    required ThemeData theme,
    required BuildContext context}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    title: Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text("Valor total"),
          Text(
              "${valorTotal(isIngreso, datos.fold(0.0, (prevValue, gasto) => prevValue + gasto.valor), extras.fold<double>(0, (previousValue, extra) => previousValue + extra.valor), ingreso)}${Values().moneda.value}")
        ],
      ),
    ),
  );
}

Widget bodyHasDatos(
    {required List<Gasto> gastos,
    required Function(String, double) onSaveValue,
    required Function(String, double) onDeleteValue,
    required ThemeData theme,
    required bool isIngresos,
    required ScrollController scrollController,
    required BuildContext context}) {
  List<Widget> cards = [];
  int contador = 1;

  for (Gasto gasto in gastos) {
    cards.add(gastoView(
        onSaveValue,
        onDeleteValue,
        (selec) => Values().gastoSeleccionado.value = selec,
        gasto.nombre,
        isIngresos ? -1 * gasto.valor : gasto.valor,
        contador,
        theme,
        context));
    contador++;
  }

  return gastos.isNotEmpty
      ? Column(children: [
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(isIngresos ? "Ingresos extra" : "Gastos básicos"),
                Text(
                    "${gastos.fold<double>(0.0, (previousValue, gasto) => isIngresos ? previousValue + (-1 * gasto.valor) : previousValue + gasto.valor).toStringAsFixed(2)}${Values().moneda.value}")
              ],
            ),
          ),
          Expanded(
            flex: 9,
            child: ListView.builder(
              controller: scrollController,
              itemCount: cards.length,
              itemBuilder: (context, index) => cards[index],
            ),
          )
        ])
      : bodyHasNoDatos();
}

Widget extrasListView(
    {required List<Gasto> extras,
    required Function(String, double, bool) onCreate,
    required Function(String, double) onSaveExtra,
    required Function(String, double) onDeleteExtra,
    required ThemeData theme,
    required BuildContext context}) {
  List<Widget> extraCards = [];

  int contador = 0;
  for (Gasto extra in extras) {
    extraCards.add(gastoView(
        onSaveExtra,
        onDeleteExtra,
        (pos) => Values().gastoSeleccionado.value = pos,
        extra.nombre,
        extra.valor,
        contador,
        theme,
        context));
    contador++;
  }

  return extras.isNotEmpty
      ? ListView(
          children: extraCards,
        )
      : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(getImageUri(ImageUris.ok), height: 200, width: 200),
              const Text("¡Que bien! no hay extras")
            ],
          ),
        );
}

Widget bodyHasNoDatos() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          getImageUri(ImageUris.buscando),
          height: 200,
          width: 200,
        ),
        const Text("Esto está muy vacio"),
      ],
    ),
  );
}

FloatingActionButton floatingButton(bool nuevo,
    {required Function onChange,
    required ScrollController scrollController,
    required BuildContext context}) {
  return FloatingActionButton.extended(
    onPressed: () => onChange(),
    icon: !nuevo
        ? const Icon(color: Colors.black, Icons.add)
        : const Icon(Icons.close),
    label: Text(
        style: TextStyle(color: Colors.black),
        nuevo ? "Cancelar" : "Crear nuevo"),
  );
}

Widget showExtras(
    {required double valorExtras,
    required Function(bool) checkExtras,
    required bool extrasChecked}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Text(
          "Ver extras (${valorExtras.toStringAsFixed(2)}${Values().moneda.value})"),
      Switch(value: extrasChecked, onChanged: checkExtras)
    ],
  );
}

RxBool _existente = false.obs;
Widget createNew(
    {required bool extraSelected,
    required Function(String, double, bool) onCreateGasto,
    required ThemeData theme,
    required bool IsIngresos,
    required List<Gasto> gastos,
    required List<Gasto> extras,
    required BuildContext context}) {
  List<DropdownMenuItem> datos = extraSelected
      ? extras
          .map((e) => DropdownMenuItem(
                value: e.nombre,
                child: Text(e.nombre),
              ))
          .toList()
      : gastos
          .where((gasto) => IsIngresos ? gasto.valor < 0 : gasto.valor > 0)
          .map((e) => DropdownMenuItem(
                value: e.nombre,
                child: Text(e.nombre),
              ))
          .toList();

  return Obx(
    () => Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: IconButton(
                onPressed: () {
                  onCreateGasto(_nombreNuevo.text,
                      double.parse(_valorNuevo.text), extraSelected);
                  _nombreNuevo.clear();
                  _valorNuevo.clear();
                },
                icon: const Icon(Icons.check),
              ),
            ),
            Expanded(
                flex: 5,
                child: _existente.value
                    ? DropdownButtonFormField(
                        items: datos,
                        onChanged: (value) => _nombreNuevo.text = value,
                        value: datos.first.value,
                      )
                    : TextField(
                        controller: _nombreNuevo,
                        decoration: const InputDecoration(labelText: "Nombre"),
                        autofocus: false,
                      )),
            Expanded(
                flex: 3,
                child: TextField(
                  controller: _valorNuevo,
                  decoration: InputDecoration(
                    labelText: "Monto",
                  ),
                  keyboardType: TextInputType.number,
                )),
          ],
        ),
        datos.isNotEmpty
            ? switchSettingView(
                onChange: (activo) => _existente.value = activo,
                text: "Elegir uno existente",
                inicial: _existente.value)
            : Container()
      ],
    ),
  );
}

Widget ingresoView(
    {required Function(double) onIngresoChange,
    required double ingreso,
    required ThemeData theme,
    required BuildContext context}) {
  _ingresoNuevo.value = TextEditingValue(text: ingreso.toStringAsFixed(2));
  return Obx(
    () => Card(
      child: _isIngresoSeleccionado.value
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    onPressed: () {
                      _isIngresoSeleccionado.value = false;
                      onIngresoChange(double.parse(_ingresoNuevo.text));
                    },
                    icon: const Icon(Icons.check),
                    iconSize: theme.textTheme.labelLarge!.fontSize),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  "Ingreso base",
                  style:
                      TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: TextFormField(
                    autofocus: true,
                    controller: _ingresoNuevo,
                    decoration: const InputDecoration(labelText: "Monto"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Ingreso base",
                    style: TextStyle(
                        fontSize: theme.textTheme.labelLarge!.fontSize)),
                TextButton(
                  child: Text(
                      "${ingreso.toStringAsFixed(2)}${Values().moneda.value}",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: theme.textTheme.labelLarge!.fontSize)),
                  onPressed: () => _isIngresoSeleccionado.value = true,
                )
              ],
            ),
    ),
  );
}
