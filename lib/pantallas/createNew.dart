import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:cuentas_android/widgets/views/createNewWidgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class createNew extends StatelessWidget {
  Rx<Gasto> _editingGasto = Gasto.empty().obs;
  TextEditingController _nombre = TextEditingController();
  TextEditingController _valor = TextEditingController();
  Rx<DateTime> _fecha = DateTime.now().obs;
  createNew({super.key, Gasto? gasto}) {
    if (gasto != null) {
      _editingGasto.value = gasto;
      _nombre.value = TextEditingValue(text: gasto.nombre.value);
      _valor.value =
          TextEditingValue(text: gasto.valor.value.toStringAsFixed(2));
      _fecha.value =
          DateTime(gasto.anno.value, gasto.mes.value, gasto.dia.value);
      tag.value = gasto.tag.value;
      Values().editing.value = true;
    } else {
      _editingGasto.value = Gasto.empty();
      _nombre.value = TextEditingValue();
      _valor.value = TextEditingValue();
      _fecha.value = DateTime.now();
      tag.value = "";
      Values().editing.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    RxList<String> tags = Values().cuentaRet.value!.tags;

    void _onSave(
        String nombre, double valor, String tag, DateTime fecha, bool editing) {
      Gasto g =
          Gasto(nombre: nombre.obs, valor: valor.obs, fecha: fecha, tag: tag);

      nombre = nombre.endsWith(" ")
          ? nombre.substring(0, nombre.length - 1)
          : nombre;

      Values().cuentaRet.value!.addUpdateValues(Values().showing.value, g,
          editing, Values().anno.value, Values().mes.value);
      Navigator.of(context).pop();
    }

    void _onNewTag() {
      TextEditingController controller = TextEditingController();
      showYesNoDialog(
          title: 'Nuevo tag',
          onYes: () {
            Values().cuentaRet.value!.tags.add(controller.text);
            if (tags.value.isNotEmpty && !tags.value.contains("")) {
              tags.value.add("");
            }
          },
          context: context,
          body: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: TextField(
              autofocus: true,
              controller: controller,
              decoration: InputDecoration(label: Text("Nuevo tag")),
            ),
          ));
    }

    return PopScope(
      child: Scaffold(
          body: Obx(
        () => SizedBox(
          height: double.infinity,
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Values().fondo.value),
                    fit: BoxFit.cover)),
            child: OrientationBuilder(
              builder: (context, orientation) => createNewHasData(
                  onSave: _onSave,
                  onCancel: () => Navigator.pop(context),
                  context: context,
                  tags: tags.value,
                  onNewTag: () => _onNewTag(),
                  nombre: _nombre,
                  valor: _valor,
                  fecha: _fecha.value,
                  isLandscape: orientation == Orientation.landscape),
            ),
          ),
        ),
      )),
    );
  }
}
