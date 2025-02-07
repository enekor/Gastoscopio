import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/createNewWidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class createNew extends StatefulWidget {
  createNew({super.key, Gasto? gasto}) {
    if (gasto != null) {
      _nombre = gasto.nombre.value;
      _valor = gasto.valor.value;
      _fecha = DateTime(gasto.anno.value, gasto.mes.value, gasto.dia.value);
      _tag = gasto.tag.value;
      Values().editing.value = true;
    } else {
      _nombre = '';
      _valor = 0;
      _fecha = DateTime.now();
      _tag = '';
      Values().editing.value = false;
    }
  }

  String _nombre = '';
  double _valor = 0;
  DateTime _fecha = DateTime.now();
  String _tag = '';

  @override
  _createNewState createState() => _createNewState();
}

class _createNewState extends State<createNew> {
  Widget _body() {
    return Center(
        child: newEditBodyVertical(
            context: context,
            fecha: widget._fecha,
            name: widget._nombre,
            valor: widget._valor.toStringAsFixed(2),
            tag: widget._tag,
            onChangeName: onEditName,
            onChangeTag: onEditTag,
            onChangeValue: onEditValue,
            onDateSelected: onEditDate,
            actualType: Values().showing.value,
            onChangeType: onChangeType,
            editar: Values().editing.value));
  }

  void onChangeType(ShowingGastos type) {
    setState(() {
      Values().showing.value = type;
    });
  }

  void onEditName(String name) {
    setState(() {
      widget._nombre = name;
    });
  }

  void onEditValue(String value) {
    setState(() {
      widget._valor = double.parse(value);
    });
  }

  void onEditDate(DateTime date) {
    setState(() {
      widget._fecha = date;
    });
  }

  void onEditTag(String tag) {
    setState(() {
      widget._tag = tag;
    });
  }

  void onSave() {
    Gasto g = Gasto(
        nombre: RxString(widget._nombre),
        valor: RxDouble(widget._valor),
        tag: widget._tag,
        fecha: widget._fecha);
    Values().cuentaRet.value!.addUpdateValues(
        Values().showing.value,
        g,
        Values().editing.value,
        widget._fecha.year,
        Values().nombresMes[widget._fecha.month - 1]);

    cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);

    onCancel();
  }

  void onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
      appBar: null,
      bottomNavigationBar: gastoBottomNavigationBar(onSave, onCancel, context),
    );
  }
}
