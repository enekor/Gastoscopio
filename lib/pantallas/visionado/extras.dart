import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/values.dart';
import 'package:get/Get.dart';
import 'package:cuentas_android/widgets/views/extrasWidgets.dart' as ew;

class Extras extends StatelessWidget {
  Extras({Key? key, required Cuenta cuenta}) : super(key: key){
    c = cuenta.obs;
    extras =  cuenta.Meses.where((v) => v.NMes == Values().GetMes() && v.Anno == Values().anno.value).first.Extras.obs;
  }

  late Rx<Cuenta> c;
  late RxList<Gasto> extras;
  RxBool nuevo = false.obs;

  RxList<Gasto> _toDelete = RxList<Gasto>([]);

  void _createExtra(String nombre, double valor){
    extras.value.add(Gasto(nombre: nombre, valor: valor));
    nuevo.value = false;
  }
  void _saveExtra(String nombre, double valor) {
    if(extras.value.where((v) => v.nombre == nombre).isNotEmpty){
      extras.value.where((v) => v.nombre == nombre).first.valor = valor;
    }
    else{
      _createExtra(nombre, valor);
    }
  }

  void _deleteExtra(String nombre, double valor){
    extras.value.removeWhere((v)=>v.nombre == nombre && v.valor == valor);
  }

  void _pop(BuildContext context) {
    c.value.Meses.where((element) => element.Anno == Values().anno.value && element.NMes == Values().GetMes()).first.Extras = extras.value;
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(c.value);
    Cuenta cuentaTemp = Cuenta(id: c.value.id, Nombre: c.value.Nombre, Meses: [Mes("NMes", Values().anno.value)], posicion: c.value.posicion);
    cuentaTemp.Meses.first.Extras = extras.value;
    Values().cuentaRet = cuentaTemp;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) => _pop(context),
      child: Obx(
        () => Scaffold(
          resizeToAvoidBottomInset: true,
          floatingActionButton: FloatingActionButton(
            child: nuevo.value == false
              ? const Icon(Icons.add)
              : const Icon(Icons.close),
            onPressed: () => nuevo.value = !nuevo.value
          ),
          body: CustomPaint(
            painter: MyPattern(context),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    extras.value.isNotEmpty
                      ?ew.GetExtras(
                        extras: extras.value,
                        onChangeExtra: _saveExtra,
                        onDeleteExtra: _deleteExtra,
                        theme: Theme.of(context)
                      )
                      :ew.extrasHasNoData(),
                    nuevo.value
                      ? ew.crearNuevo(onCreateExtra: _createExtra)
                      : const SizedBox()
                  ],
                ),
              )
            ),
          )
        ),
      ),
    );
  }
}
