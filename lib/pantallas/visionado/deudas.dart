import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/deudasWidget.dart';
import 'package:flutter/material.dart';

late List<Cuenta> _cuentas;
late List<Gasto> _debts;
late Cuenta _cuenta;

class deudas extends StatefulWidget {
  deudas({Key? key, required Cuenta cuenta, required List<Cuenta> cuentas})
      : super(key: key) {
    _debts = cuenta.deudas;
    _cuenta = cuenta;
    _cuentas = cuentas;
  }

  @override
  State<deudas> createState() => _deudasState();
}

class _deudasState extends State<deudas> {
  void _onCreate(String nombre, double valor) {
    if (_debts.where((deuda) => deuda.nombre == nombre).isNotEmpty) {
      _debts.firstWhere((deuda) => deuda.nombre == nombre).valor += valor;
    } else {
      _debts.add(Gasto(nombre: nombre, valor: valor));
    }

    setState(() {});
  }

  void _onDelete(String nombre, double valor) {
    setState(() {
      _debts.removeWhere(
          (deuda) => deuda.nombre == nombre && deuda.valor == valor);
    });
  }

  void _onEdit(String nombre, double valor) {
    setState(() {
      _debts.firstWhere((deuda) => deuda.nombre == nombre).valor = valor;
    });
  }

  void _pop(BuildContext context) {
    _cuenta.deudas = _debts;
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(_cuenta);
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Values().cuentaRet = _cuenta;
  }

  bool _nuevo = false;
  void _setNuevo() {
    setState(() {
      _nuevo = !_nuevo;
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
        resizeToAvoidBottomInset: true,
        floatingActionButton:
            floatingButton(context: context, onClick: _setNuevo),
        appBar: appBar(
            debts: _cuenta.deudas,
            onSettings: () => _navigateSettings(context),
            context: context),
        body: CustomPaint(
          painter: MyPattern(context),
          child: Center(
            child: Column(
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
                            "Deudas"),
                        _nuevo
                            ? nuevaDeuda(
                                onCreate: _onCreate,
                                theme: Theme.of(context),
                                context: context)
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: _cuenta.deudas.isNotEmpty
                      ? bodyHasDatos(
                          deudas: _debts,
                          onDelete: _onDelete,
                          onEdit: _onEdit,
                          theme: Theme.of(context),
                          context: context)
                      : bodyHasNoDatos(theme: Theme.of(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
