import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pantallas/createNew.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:flutter/foundation.dart';
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
RxString _showOrderBy = ''.obs;

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
            ? DateTime(_yearFilter.value, _monthFilter.value, _dayFilter.value)
            : null,
        Values().orderBy.value)
    .obs;

void changeGastos() {
  _gastos.value = Values().cuentaRet.value!.GetGastosToShow(
      Values().showing.value,
      _tagSelected.value,
      Values().anno.value,
      Values().mes.value,
      _filterWord.value,
      _dateFiltered.value
          ? DateTime(_yearFilter.value, _monthFilter.value, _dayFilter.value)
          : null,
      Values().orderBy.value);
}

void orderBySelected(OrderByTypes order, BuildContext context) {
  Values().orderBy.value = order;
  changeGastos();

  switch (order) {
    case OrderByTypes.dateAsc:
      _showOrderBy.value = 'Fecha ascendente';
      break;

    case OrderByTypes.dateDesc:
      _showOrderBy.value = 'Fecha descendente';
      break;
    case OrderByTypes.value:
      _showOrderBy.value = 'Cantidad';
      break;
    case OrderByTypes.name:
      _showOrderBy.value = 'Nombre';
      break;
  }

  Navigator.of(context).pop();
}

void onGastosTap() {
  Values().showing.value = ShowingGastos.gastos;
  changeGastos();
}

void onIngresosTap() {
  Values().showing.value = ShowingGastos.ingresos;
  changeGastos();
}

void onExtrasTap() {
  Values().showing.value = ShowingGastos.extras;
  changeGastos();
}

void _onTag(String tag) {
  if (_tagSelected.value == tag) {
    _tagSelected.value = "";
  } else {
    _tagSelected.value = tag;
  }

  changeGastos();
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
          decoration: const InputDecoration(label: Text("Nuevo tag")),
        ),
      ));
}

void _onEdit(BuildContext context, Gasto gasto) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        insetPadding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: SizedBox(
            width: double.infinity, // Ocupa todo el ancho disponible
            child: createNew(gasto: gasto),
          ),
        ),
      );
    },
  );
}

Future<bool> _onDelete(Gasto gasto, BuildContext context) async {
  bool borrar = false;

  final snackController = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Expanded(
          flex: 6,
          child: Text(
            "¿Desea borrar ${gasto.nombre.value}?",
          ),
        ),
        Expanded(
          flex: 2,
          child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                bool borrado = Values().cuentaRet.value!.DeleteValue(
                    gasto,
                    Values().anno.value,
                    Values().mes.value,
                    Values().showing.value);
                borrar = true;
                if (!borrado) {
                  //mostrar mensaje de no borrado
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("No se ha podido borrar ${gasto.nombre.value}"),
                          const Icon(
                            Icons.cancel_rounded,
                          )
                        ],
                      ),
                    ),
                  ));
                }
              },
              icon: const Icon(
                Icons.check_circle,
              )),
        ),
        Expanded(
          flex: 2,
          child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              icon: const Icon(
                Icons.cancel_rounded,
              )),
        ),
      ],
    ),
  ));

  await snackController.closed;

  cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
  return borrar;
}

/*widgets*/
Widget IngresosGastosHasData(BuildContext context, {bool isLandscape = false}) {
  changeGastos();
  return Padding(
    padding: const EdgeInsets.only(top: kToolbarHeight),
    child: Column(
      children: [
        topPart(context),
        editIngreso(context),
        Expanded(
            child: valuesPart(context, (g) => _onEdit(context, g),
                (g) => _onDelete(g, context),
                isLandscape: isLandscape)),
        totalPart()
      ],
    ),
  );
}

Widget totalPart() => Obx(() {
      return Card(
        color: Theme.of(Get.context!).colorScheme.secondary.withAlpha(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text("Total a mostrar"),
            Text(
              style: const TextStyle(fontWeight: FontWeight.bold),
              '${_gastos.value.fold<double>(
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
  return Padding(
    padding: const EdgeInsets.only(top: 15.0),
    child: Obx(
      () => Column(
        children: [
          topCardFilters(context),
          SizedBox(
              width: double.infinity, height: 80, child: topTagsCards(context)),
          AnimatedContainer(
            height: _showMoreFilters.value ? 50 : 0,
            duration: const Duration(milliseconds: 150),
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
      padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CardButton(
                color: Values().showing.value == ShowingGastos.gastos
                    ? Theme.of(context).colorScheme.primary.withAlpha(20)
                    : null,
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
                    ? Theme.of(context).colorScheme.primary.withAlpha(20)
                    : null,
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
                    ? Theme.of(context).colorScheme.primary.withAlpha(20)
                    : null,
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
              child: const Icon(Icons.add_circle_rounded, size: 25),
            ),
          ),
          Expanded(
            flex: 9,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChipButton(
                    selected: Values().showing.value == ShowingGastos.fijo,
                    onPressed: () {
                      Values().showing.value = ShowingGastos.fijo;
                      changeGastos();
                    },
                    text: 'Fijos'),
                ActionChipButton(
                    selected: Values().showing.value == ShowingGastos.deuda,
                    onPressed: () {
                      Values().showing.value = ShowingGastos.deuda;
                      changeGastos();
                    },
                    text: 'Deudas'),
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
                      .where((tag) =>
                          Values().cuentaRet.value!.tags.value.contains(tag))
                      .map((tag) => GestureDetector(
                            onLongPress: () => onDeleteTag(tag, context),
                            child: ActionChipButton(
                              selected: _tagSelected.value == tag,
                              onPressed: () => _onTag(tag),
                              text: tag.isEmpty ? 'Todos' : tag,
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
            children: [
              ActionChipButton(
                  selected: _showOrderBy.value != '',
                  text: 'Ordenar por: ${_showOrderBy.value}',
                  icon: const Icon(Icons.sort_rounded),
                  onPressed: () => showOrderByDialog(context)),
              ActionChipButton(
                  selected: _dateFiltered.value,
                  text: _dateFiltered.value
                      ? '${_yearFilter.value}/${_monthFilter.value}/${_dayFilter.value}'
                      : "Filtrar",
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () => showCalendarDialog(context)),
              _dateFiltered.value
                  ? CardButton(
                      child: const Icon(Icons.remove),
                      color: Colors.red,
                      onPressed: () {
                        _dateFiltered.value = false;
                        changeGastos();
                      },
                      context: context,
                      padding: 5)
                  : Container(),
              ActionChipButton(
                  selected: _filterWord.value != '',
                  text: _filterWord.value,
                  onPressed: () => showSearchDialog(context),
                  icon: const Icon(Icons.search_rounded)),
              _filterWord.value != ''
                  ? CardButton(
                      child: const Icon(Icons.remove),
                      color: Colors.red,
                      onPressed: () {
                        _filterWord.value = '';
                        changeGastos();
                      },
                      context: context,
                      padding: 5)
                  : Container(),
            ],
          ),
        )),
  );
}

Widget editIngreso(BuildContext context) {
  return Obx(() {
    void editValue(String value) {
      Values()
          .cuentaRet
          .value!
          .Meses
          .firstWhere((v) =>
              v.Anno.value == Values().anno.value &&
              v.NMes.value == Values().mes.value)
          .Ingreso
          .value = double.parse(value);

      cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
    }

    return Values().showing.value == ShowingGastos.ingresos
        ? Padding(
            padding:
                const EdgeInsets.only(left: 15, right: 14, top: 8, bottom: 3),
            child: CardButton(
              margin: 0,
              padding: 10,
              context: context,
              onPressed: () => editIngresoPopup(
                  context,
                  editValue,
                  Values()
                      .cuentaRet
                      .value!
                      .Meses
                      .firstWhere((v) =>
                          v.Anno.value == Values().anno.value &&
                          v.NMes.value == Values().mes.value)
                      .Ingreso
                      .toStringAsFixed(2)),
              child: Text(
                  'Ingreso base de ${Values().mes.value}     ${Values().cuentaRet.value!.Meses.firstWhere((v) => v.Anno.value == Values().anno.value && v.NMes.value == Values().mes.value).Ingreso.toStringAsFixed(2)}${Values().moneda.value}'),
            ),
          )
        : Container();
  });
}

void editIngresoPopup(
    BuildContext context, Function(String) onEdit, String initialValue) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      TextEditingController controller =
          TextEditingController(text: initialValue);
      return AlertDialog(
        title: const Text('Editar Valor'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
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

Widget valuesPart(
    BuildContext context, void Function(Gasto) onEdit, Function(Gasto) onDelete,
    {bool isLandscape = false}) {
  return Obx(
    () => Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withAlpha(20),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.only(
          left: isLandscape ? 150 : 10,
          right: isLandscape ? 150 : 10,
          top: 10,
          bottom: 10),
      child: ListView.builder(
          itemCount: _gastos.value.length,
          itemBuilder: (c, i) {
            return Dismissible(
                key: Key(_gastos[i].nombre + _gastos[i].valor.toString()),
                secondaryBackground: Container(
                  color: Colors.red,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.delete),
                    ),
                  ),
                ),
                background: Container(
                  color: Colors.red,
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(Icons.delete),
                    ),
                  ),
                ),
                confirmDismiss: (direction) async => await onDelete(_gastos[i]),
                onDismissed: (_) {
                  changeGastos();
                },
                child: gastoView(
                    gasto: _gastos.value[i],
                    onTapEdit: onEdit,
                    context: context));
          }),
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
                autofocus: true,
                decoration: const InputDecoration(
                    suffixIcon: Icon(
                      Icons.search,
                      size: 25,
                    ),
                    labelText: "Filtrar"),
                onChanged: (value) {
                  _filterWord.value = value;
                  changeGastos();
                },
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
  _dateFiltered.value = true;
  _yearFilter.value = picked!.year;
  _monthFilter.value = picked.month;
  _dayFilter.value = picked.day;

  changeGastos();
}

void showOrderByDialog(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround, // Distribuye espacio
              children: [
                ActionChipButton(
                    selected: _showOrderBy.value == 'Fecha ascendente',
                    text: 'Fecha ascendente',
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () =>
                        orderBySelected(OrderByTypes.dateAsc, context)),
                ActionChipButton(
                    selected: _showOrderBy.value == 'Fecha descendente',
                    text: 'Fecha descendente',
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () =>
                        orderBySelected(OrderByTypes.dateDesc, context)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ActionChipButton(
                    selected: _showOrderBy.value == 'Nombre',
                    text: 'Nombre',
                    icon: const Icon(Icons.abc),
                    onPressed: () =>
                        orderBySelected(OrderByTypes.name, context)),
                ActionChipButton(
                    selected: _showOrderBy.value == 'Valor',
                    text: 'Valor',
                    icon: const Icon(Icons.numbers),
                    onPressed: () =>
                        orderBySelected(OrderByTypes.value, context)),
              ],
            ),
          ],
        ),
      );
    },
  );
}
