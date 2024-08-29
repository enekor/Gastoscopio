import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pantallas/createNew.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/* funcionalidad */
RxString _tagSelected = "".obs;
RxString _filterWord = "".obs;
RxBool _dateFiltered = false.obs;
RxInt _yearFilter = DateTime.now().year.obs;
RxInt _monthFilter = DateTime.now().month.obs;
RxInt _dayFilter = DateTime.now().day.obs;
RxBool _showMoreFilters = false.obs;

void onGastosTap() {
  Values().showing.value = ShowingGastos.gastos;
}

void onIngresosTap() {
  Values().showing.value = ShowingGastos.ingresos;
}

void onExtrasTap() {
  Values().showing.value = ShowingGastos.extras;
}

void _onTag(String tag) {
  if (_tagSelected.value == tag) {
    _tagSelected.value = "";
  } else {
    _tagSelected.value = tag;
  }
}

void onDeleteTag(String tag, BuildContext context) {
  showYesNoDialog(
      title: 'Borrar tag',
      onYes: () => Values().cuentaRet.value!.tags.remove(tag),
      context: context,
      body: Text('Desea borrar el tag $tag'));
}

void onNewTag(BuildContext context) {
  TextEditingController controller = TextEditingController();
  showYesNoDialog(
      title: 'Nuevo tag',
      onYes: () {
        Values().cuentaRet.value!.tags.add(controller.text);
        _filterWord.value = "";
      },
      context: context,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(label: Text("Nuevo tag")),
        ),
      ));
}

void _onEdit(BuildContext context, Gasto gasto) {
  Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => createNew(
            gasto: gasto,
          )));
}

/*widgets*/
Widget IngresosGastosHasData(BuildContext context, {bool isLandscape = false}) {
  return Column(
    children: [
      topPart(context),
      Expanded(
          child: valuesPart(context, (g) => _onEdit(context, g),
              isLandscape: isLandscape)),
      totalPart()
    ],
  );
}

Widget totalPart() => Obx(() {
      RxList<Gasto> _gastos = Values()
          .cuentaRet
          .value!
          .GetGastosToShow(
              Values().showing.value,
              _tagSelected.value,
              Values().anno.value,
              Values().mes.value,
              _filterWord.value,
              _dateFiltered.value
                  ? DateTime(
                      _yearFilter.value, _monthFilter.value, _dayFilter.value)
                  : null)
          .obs;
      return Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("Total a mostrar"),
            Text(
              style: TextStyle(fontWeight: FontWeight.bold),
              '${_gastos.fold<double>(
                    0,
                    (previousValue, element) =>
                        previousValue + element.valor.value,
                  ).toStringAsFixed(2)}${Values().moneda.value}',
            )
          ],
        ),
      );
    });

Widget topPart(BuildContext context) {
  // return Card.filled(
  //   color: GetColor(ColorTypes.primary, context),
  //   shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //     topLeft: Radius.circular(0),
  //     topRight: Radius.circular(0),
  //     bottomLeft: Radius.circular(25),
  //     bottomRight: Radius.circular(25),
  //   )),
  //   margin: EdgeInsets.all(0),
  //   child:
  return Padding(
    padding: const EdgeInsets.only(top: 15.0),
    child: Obx(
      () => Column(
        children: [
          topCardFilters(context),
          SizedBox(
              width: double.infinity, height: 30, child: topTagsCards(context)),
          AnimatedContainer(
            height: _showMoreFilters.value ? 50 : 0,
            duration: Duration(milliseconds: 150),
            child: Column(
              children: [topSearchBar(context)],
            ),
          ),
        ],
      ),
    ),
    //),
  );
}

Widget topCardFilters(BuildContext context) {
  return Obx(
    () => Padding(
      padding: EdgeInsets.only(right: 10, left: 10, top: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CardButton(
                color: Values().showing.value == ShowingGastos.gastos
                    ? GetColor(ColorTypes.background, context)
                    : GetColor(ColorTypes.secondary, context),
                onPressed: onGastosTap,
                child: Column(
                  children: [
                    const Text('Gastos'),
                    Text(
                        '${Values().cuentaRet.value!.GetGastos(Values().anno.value, Values().mes.value).toStringAsFixed(2)}${Values().moneda.value}')
                  ],
                ),
                padding: Values().showing.value == ShowingGastos.gastos ? 5 : 2,
                context: context,
                margin: 0),
          ),
          Expanded(
            flex: 1,
            child: CardButton(
                color: Values().showing.value == ShowingGastos.ingresos
                    ? GetColor(ColorTypes.background, context)
                    : GetColor(ColorTypes.secondary, context),
                onPressed: onIngresosTap,
                child: Column(
                  children: [
                    const Text('Ingresos'),
                    Text(
                        '${Values().cuentaRet.value!.GetIngresos(Values().anno.value, Values().mes.value).toStringAsFixed(2)}${Values().moneda.value}')
                  ],
                ),
                padding:
                    Values().showing.value == ShowingGastos.ingresos ? 10 : 5,
                context: context,
                margin: 5),
          ),
          Expanded(
            flex: 1,
            child: CardButton(
                color: Values().showing.value == ShowingGastos.extras
                    ? GetColor(ColorTypes.background, context)
                    : GetColor(ColorTypes.secondary, context),
                onPressed: onExtrasTap,
                child: Column(
                  children: [
                    const Text('Extras'),
                    Text(
                        '${Values().cuentaRet.value!.GetExtras(Values().anno.value, Values().mes.value).toStringAsFixed(2)}${Values().moneda.value}')
                  ],
                ),
                padding:
                    Values().showing.value == ShowingGastos.extras ? 10 : 5,
                context: context,
                margin: 0),
          ),
        ],
      ),
    ),
  );
}

Widget topTagsCards(BuildContext context) {
  return Obx(
    () => Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
                onTap: () => _showMoreFilters.value = !_showMoreFilters.value,
                child: AnimatedArrow(_showMoreFilters.value)),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => onNewTag(context),
              child: Icon(Icons.add_circle_rounded,
                  color: GetColor(ColorTypes.tertiary, context), size: 25),
            ),
          ),
          Expanded(
            flex: 9,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChipButton(
                  color: Values().showing.value == ShowingGastos.fijo
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.tertiary, context),
                  onPressed: () => Values().showing.value = ShowingGastos.fijo,
                  text: Text(
                    'Fijos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Values().showing.value == ShowingGastos.fijo
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black
                          : Colors.black,
                    ),
                  ),
                ),
                ActionChipButton(
                  color: Values().showing.value == ShowingGastos.deuda
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.tertiary, context),
                  onPressed: () => Values().showing.value = ShowingGastos.deuda,
                  text: Text(
                    'Deudas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Values().showing.value == ShowingGastos.deuda
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black
                          : Colors.black,
                    ),
                  ),
                ),
                Row(
                  children: Values()
                      .cuentaRet
                      .value!
                      .Meses
                      .value
                      .firstWhere((m) =>
                          m.Anno.value == Values().anno.value &&
                          m.NMes.value == Values().mes.value)
                      .GetTags()
                      .map((tag) => ActionChipButton(
                            color: _tagSelected.value == tag
                                ? GetColor(ColorTypes.background, context)
                                : GetColor(ColorTypes.secondary, context),
                            onPressed: () => _onTag(tag),
                            text: Text(
                              tag.isEmpty ? 'Todos' : tag,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                      .toList(),
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget topSearchBar(BuildContext context) {
  return Obx(
    () => Padding(
        padding: const EdgeInsets.only(right: 10, left: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActionChipButton(
                  text: Text(_dateFiltered.value
                      ? '${_yearFilter.value}/${_monthFilter.value}/${_dayFilter.value}'
                      : "Filtrar"),
                  color: _dateFiltered.value
                      ? GetColor(ColorTypes.background, context)
                      : GetColor(ColorTypes.secondary, context),
                  icon: Icon(Icons.calendar_month_rounded),
                  onPressed: () => showCalendarDialog(context)),
              _dateFiltered.value
                  ? CardButton(
                      child: Icon(Icons.remove),
                      color: Colors.red,
                      onPressed: () => _dateFiltered.value = false,
                      context: context,
                      padding: 5)
                  : Container(),
              ActionChipButton(
                  text: Text(_filterWord.value),
                  color: GetColor(ColorTypes.secondary, context),
                  onPressed: () => showSearchDialog(context),
                  icon: Icon(Icons.search_rounded)),
              _filterWord.value != ''
                  ? CardButton(
                      child: Icon(Icons.remove),
                      color: Colors.red,
                      onPressed: () => _filterWord.value = '',
                      context: context,
                      padding: 5)
                  : Container(),
            ],
          ),
        )),
  );
}

Widget valuesPart(BuildContext context, void Function(Gasto) onEdit,
    {bool isLandscape = false}) {
  return Obx(
    () => Card(
      margin: EdgeInsets.only(
          left: isLandscape ? 150 : 10,
          right: isLandscape ? 150 : 10,
          top: 10,
          bottom: 10),
      color: GetColor(ColorTypes.primary, context).withOpacity(0.84),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Values().showing.value == ShowingGastos.ingresos
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            flex: 6,
                            child: Center(child: Text("Ingreso base"))),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 50.0),
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              onChanged: (value) => Values()
                                  .cuentaRet
                                  .value!
                                  .Meses
                                  .firstWhere((v) =>
                                      v.Anno.value == Values().anno.value &&
                                      v.NMes.value == Values().mes.value)
                                  .Ingreso
                                  .value = double.parse(value),
                              initialValue: Values()
                                  .cuentaRet
                                  .value!
                                  .Meses
                                  .firstWhere((v) =>
                                      v.Anno.value == Values().anno.value &&
                                      v.NMes.value == Values().mes.value)
                                  .Ingreso
                                  .toString(),
                              decoration: InputDecoration(
                                  suffix: Text(Values().moneda.value)),
                            ),
                          ),
                        )
                      ],
                    )
                  : Container(),
              Column(
                children: Values()
                    .cuentaRet
                    .value!
                    .GetGastosToShow(
                        Values().showing.value,
                        _tagSelected.value,
                        Values().anno.value,
                        Values().mes.value,
                        _filterWord.value,
                        _dateFiltered.value
                            ? DateTime(_yearFilter.value, _monthFilter.value,
                                _dayFilter.value)
                            : null)
                    .obs
                    .map((gasto) => gastoView(
                        gasto: gasto, onTapEdit: onEdit, context: context))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void showSearchDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                    suffixIcon: Icon(
                      Icons.search,
                      color: GetColor(ColorTypes.text, context),
                      size: 25,
                    ),
                    labelText: "Filtrar"),
                onChanged: (value) => _filterWord.value = value,
              ),
            ),
          ));
}

void showCalendarDialog(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );
  if (picked != null) {
    _dateFiltered.value = true;
    _yearFilter.value = picked.year;
    _monthFilter.value = picked.month;
    _dayFilter.value = picked.day;
  }
}
