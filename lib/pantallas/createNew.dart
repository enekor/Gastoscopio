import 'dart:io';

import 'package:cuentas_android/pantallas/gastosFromImage.dart';
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

  Rx<File?> _imagen = Rx<File?>(null);
  @override
  Widget build(BuildContext context) {
    RxList<String> tags = Values().cuentaRet.value!.tags;

    void sacarFoto() async {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _imagen.value = File(image.path);
      }
    }

    void procesarFoto() {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GastosfromImage(image: _imagen.value!)),
      ).then((value) {
        (value as List<Gasto>).forEach((gasto) {
          gasto.nombre.value = gasto.nombre.value.endsWith(" ")
              ? gasto.nombre.value.substring(0, gasto.nombre.value.length - 1)
              : gasto.nombre.value;

          Values().cuentaRet.value!.addUpdateValues(Values().showing.value,
              gasto, false, Values().anno.value, Values().mes.value);
          cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
        });
      });
    }

    void onCamera() {
      showModalBottomSheet(
          context: context,
          builder: (context) => Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Seleccionar una foto'),
                    const SizedBox(
                      height: 10,
                    ),
                    _imagen.value != null
                        ? kIsWeb
                            ? Text('Imagen seleccionada')
                            : AspectRatio(
                                aspectRatio: 1.5,
                                child: Image.file(_imagen.value!),
                              )
                        : Container(),
                    const SizedBox(
                      height: 10,
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: sacarFoto, child: Text('seleccionar')),
                        _imagen.value != null
                            ? ElevatedButton(
                                onPressed: procesarFoto,
                                child: Text('Procesar'))
                            : Container()
                      ],
                    )
                  ],
                ),
              ));
    }

    void onSave(
        String nombre, double valor, String tag, DateTime fecha, bool editing) {
      Gasto g =
          Gasto(nombre: nombre.obs, valor: valor.obs, fecha: fecha, tag: tag);

      nombre = nombre.endsWith(" ")
          ? nombre.substring(0, nombre.length - 1)
          : nombre;

      Values().cuentaRet.value!.addUpdateValues(Values().showing.value, g,
          editing, Values().anno.value, Values().mes.value);
      cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
      Navigator.of(context).pop();
    }

    void onNewTag() {
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
              decoration: const InputDecoration(label: Text("Nuevo tag")),
            ),
          ));
    }

    return PopScope(
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CreateNewAppBar(onCamera: onCamera),
          body: Obx(
            () => SizedBox(
              height: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(Values().fondo.value),
                        fit: BoxFit.cover)),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OrientationBuilder(
                    builder: (context, orientation) => createNewHasData(
                        onSave: onSave,
                        onCancel: () => Navigator.pop(context),
                        context: context,
                        tags: tags.value,
                        onNewTag: () => onNewTag(),
                        nombre: _nombre,
                        valor: _valor,
                        fecha: _fecha.value,
                        isLandscape: orientation == Orientation.landscape),
                  ),
                ),
              ),
            ),
          )),
    );
  }
}
