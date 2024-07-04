import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/ingresosGastosWidget.dart';
import 'package:flutter/material.dart';

late List<Cuenta> _cuentas;
late List<Gasto> _datos;
late List<Gasto> _extras;
late double _ingreso;
late Cuenta _cuenta;
late bool _isIngresos;
late String _mes;
ScrollController _scrollController = ScrollController();
bool _nuevo = false;
bool _showExtras = false;

class IngresosGastos extends StatefulWidget {
  IngresosGastos(
      {Key? key,
      required List<Cuenta> cuentas,
      required Cuenta cuenta,
      required String mes,
      required bool isIngresos})
      : super(key: key) {
    _cuentas = cuentas;
    _cuenta = cuenta;
    Mes mesCompleto = cuenta.Meses.firstWhere(
        (m) => m.NMes == mes && m.Anno == Values().anno.value);
    _isIngresos = isIngresos;
    _datos = isIngresos
        ? mesCompleto.Gastos.where((gasto) => gasto.valor < 0).toList()
        : mesCompleto.Gastos.where((gasto) => gasto.valor > 0).toList();
    _ingreso = cuenta.Meses.where((mes) =>
            mes.NMes == Values().GetMes() && mes.Anno == Values().anno.value)
        .first
        .Ingreso;
    _mes = mes;
    _extras = cuenta.Meses.where((mes) =>
            mes.NMes == Values().GetMes() && mes.Anno == Values().anno.value)
        .first
        .Extras;
  }

  @override
  State<IngresosGastos> createState() => _IngresosGastosState();
}

class _IngresosGastosState extends State<IngresosGastos> {
  void _pop(BuildContext context) {
    if (_isIngresos) {
      _cuenta.Meses.where(
              (m) => m.NMes == _mes && m.Anno == Values().anno.value)
          .first
          .Gastos
          .removeWhere((gasto) => gasto.valor < 0);
    } else {
      _cuenta.Meses.where(
              (m) => m.NMes == _mes && m.Anno == Values().anno.value)
          .first
          .Gastos
          .removeWhere((gasto) => gasto.valor > 0);
    }
    _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value)
        .first
        .Gastos
        .addAll(_datos);
    _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value)
        .first
        .Ingreso = _ingreso;
    _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value)
        .first
        .Extras = _extras;

    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(_cuenta);
    Values().cuentaRet = _cuenta;
  }

  void _onCreateGasto(String nombre, double valor, bool extra) {
    nombre =
        nombre.endsWith(" ") ? nombre.substring(0, nombre.length - 1) : nombre;
    if (_isIngresos) {
      valor = -1 * valor;
      if (_datos.where((gasto) => gasto.nombre == nombre).isNotEmpty) {
        _datos.firstWhere((gasto) => gasto.nombre == nombre).valor += valor;
      } else {
        _datos.add(Gasto(nombre: nombre, valor: valor));
      }
    } else {
      if (extra) {
        if (_extras.where((gasto) => gasto.nombre == nombre).isNotEmpty) {
          _extras.firstWhere((gasto) => gasto.nombre == nombre).valor += valor;
        } else {
          _extras.add(Gasto(nombre: nombre, valor: valor));
        }
      } else {
        if (_datos.where((gasto) => gasto.nombre == nombre).isNotEmpty) {
          _datos.firstWhere((gasto) => gasto.nombre == nombre).valor += valor;
        } else {
          _datos.add(Gasto(nombre: nombre, valor: valor));
        }
      }
    }

    setState(() {
      _nuevo = !_nuevo;
    });
  }

  void _onSaveValue(String nombre, double valor) {
    nombre =
        nombre.endsWith(" ") ? nombre.substring(0, nombre.length - 1) : nombre;
    valor = _isIngresos ? -1 * valor : valor;
    setState(() {
      _datos.where((gasto) => gasto.nombre == nombre).first.valor = valor;
    });
  }

  void _onSaveExtra(String nombre, double valor) {
    nombre =
        nombre.endsWith(" ") ? nombre.substring(0, nombre.length - 1) : nombre;
    setState(() {
      _extras.firstWhere((extra) => extra.nombre == nombre).valor = valor;
    });
  }

  void _onDeleteValue(String nombre, double valor) {
    nombre =
        nombre.endsWith(" ") ? nombre.substring(0, nombre.length - 1) : nombre;
    valor = _isIngresos ? -1 * valor : valor;
    setState(() {
      _datos.removeWhere(
          (gasto) => gasto.nombre == nombre && gasto.valor == valor);
    });
  }

  void _onDeleteExtra(String nombre, double valor) {
    nombre =
        nombre.endsWith(" ") ? nombre.substring(0, nombre.length - 1) : nombre;
    setState(() {
      _extras.removeWhere(
          (extra) => extra.nombre == nombre && extra.valor == valor);
    });
  }

  void _onIngresoChange(double valor) {
    setState(() {
      _ingreso = valor;
    });
  }

  void _setNuevo() {
    setState(() {
      _nuevo = !_nuevo;
    });
  }

  void _checkExtras(bool checked) {
    setState(() {
      _showExtras = checked;
    });
  }

  void _navigateSettings(BuildContext context) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Settings(cc: _cuentas)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) => _pop(context),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: true,
        appBar: appBar(
            context: context,
            datos: _datos,
            extras: _extras,
            ingreso: _ingreso,
            isIngreso: _isIngresos,
            onSettings: () => _navigateSettings(context)),
        floatingActionButton: floatingButton(_nuevo,
            onChange: _setNuevo,
            scrollController: _scrollController,
            context: context),
        body: CustomPaint(
            painter: MyPattern(context),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Card(
                    margin: EdgeInsets.all(0),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25))),
                    child: Column(
                      children: [
                        Text(
                            style: Theme.of(context).textTheme.bodyLarge,
                            _isIngresos ? "Ingresos" : "Gastos"),
                        _isIngresos
                            ? ingresoView(
                                onIngresoChange: _onIngresoChange,
                                ingreso: _ingreso,
                                theme: Theme.of(context),
                                context: context)
                            : Container(),
                        !_isIngresos
                            ? showExtras(
                                valorExtras: _extras.fold(
                                    0.0,
                                    (previousValue, element) =>
                                        previousValue + element.valor),
                                checkExtras: _checkExtras,
                                extrasChecked: _showExtras)
                            : Container(),
                        _nuevo
                            ? createNew(
                                extraSelected: _showExtras,
                                onCreateGasto: _onCreateGasto,
                                theme: Theme.of(context),
                                IsIngresos: _isIngresos,
                                gastos: _datos,
                                extras: _extras,
                                context: context)
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: _isIngresos
                      ? bodyHasDatos(
                          gastos: _datos,
                          onSaveValue: _onSaveValue,
                          onDeleteValue: _onDeleteValue,
                          theme: Theme.of(context),
                          isIngresos: _isIngresos,
                          scrollController: _scrollController,
                          context: context)
                      : _showExtras
                          ? extrasListView(
                              extras: _extras,
                              onCreate: _onCreateGasto,
                              onSaveExtra: _onSaveExtra,
                              onDeleteExtra: _onDeleteExtra,
                              theme: Theme.of(context),
                              context: context)
                          : bodyHasDatos(
                              gastos: _datos,
                              onSaveValue: _onSaveValue,
                              onDeleteValue: _onDeleteValue,
                              theme: Theme.of(context),
                              isIngresos: _isIngresos,
                              scrollController: _scrollController,
                              context: context),
                )
              ],
            )),
      ),
    );
  }
}
