import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:cuentas_android/widgets/views/createNewWidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class createNew extends StatelessWidget {
  final Rx<Gasto> _editingGasto = Gasto.empty().obs;
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _valor = TextEditingController();
  final Rx<DateTime> _fecha = DateTime.now().obs;
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
      _nombre.value = const TextEditingValue();
      _valor.value = const TextEditingValue();
      _fecha.value = DateTime.now();
      tag.value = "";
      Values().editing.value = false;
    }
  }

  final Rx<File?> _imagen = Rx<File?>(null);
  @override
  Widget build(BuildContext context) {
    RxList<String> tags = Values().cuentaRet.value!.tags;

    void sacarFoto() async {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _imagen.value = File(image.path);
      }
    }

    void onSave(
        String nombre, double valor, String tag, DateTime fecha, bool editing) {
      Gasto g =
          Gasto(nombre: nombre.obs, valor: valor.obs, fecha: fecha, tag: tag);

      nombre = nombre.endsWith(" ")
          ? nombre.substring(0, nombre.length - 1)
          : nombre;

      print("guardando");
      Values().cuentaRet.value!.addUpdateValues(Values().showing.value, g,
          editing, Values().nombresMes[g.mes.value - 1]);
      cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
      Navigator.of(context).pop();
    }

    void onNewTag(Function(String) onAdd) {
      TextEditingController controller = TextEditingController();
      showYesNoDialog(
          title: 'Nuevo tag',
          onYes: () {
            Values().cuentaRet.value!.tags.add(controller.text);
            if (tags.value.isNotEmpty && !tags.value.contains("")) {
              tags.value.add("");
            }

            onAdd(controller.text);
          },
          context: context,
          body: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: TextField(
              autofocus: true,
              controller: controller,
              decoration: const InputDecoration(label: Text("Nuevo tag")),
            ),
          ));
    }

    return PopScope(
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CreateNewAppBar(),
          extendBody: true,
          bottomNavigationBar: Container(
            color: Colors.transparent,
            child: SizedBox(
              height: 80,
              child: buttonsPart(
                  onSave: onSave,
                  onCancel: () => Navigator.pop(context),
                  context: context,
                  nombre: _nombre,
                  valor: _valor),
            ),
          ),
          body: Obx(
            () => SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Container(
                decoration: Values().mostrarFondoDinamico.value
                    ? BoxDecoration(
                        image: DecorationImage(
                            colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken),
                            image: AssetImage(Values().fondo.value),
                            fit: BoxFit.cover))
                    : null,
                child: OrientationBuilder(
                  builder: (context, orientation) => createNewHasData(
                      onSave: onSave,
                      onCancel: () => Navigator.pop(context),
                      context: context,
                      tags: tags.value,
                      onNewTag: (func) => onNewTag(func),
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
