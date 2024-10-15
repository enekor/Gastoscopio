import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class cuentaDao {
  CollectionReference ref = FirebaseFirestore.instance.collection('cuenta');
  User? user = Auth().currentUser;
  static int count = 0;

  Future<List<Cuenta>> getDatosJson() async {
    String jsonCuentaWeb =
        '{"id":"eqqpOnfDzsea4X6VEPRf2RnF6jc2","Nombre":"App test","Meses":[{"Gastos":[{"nombre":"Casa","valor":850.0,"anno":2024,"mes":9,"dia":10,"tag":"indispensable"},{"nombre":"Bizum amigo","valor":-3.0,"anno":2024,"mes":9,"dia":10,"tag":""}],"Ingreso":1340.0,"Extras":[{"nombre":"Cine","valor":12.5,"anno":2024,"mes":9,"dia":4,"tag":"ocio"},{"nombre":"Compras del mes","valor":1500.0,"anno":2024,"mes":9,"dia":10,"tag":"compras"}],"NMes":"Septiembre","Anno":2024}],"posicion":3,"fijos":[{"nombre":"Casa","valor":850.0,"anno":2024,"mes":9,"dia":10,"tag":"indispensable"}],"deudas":[{"nombre":"Prestamo coche","valor":30678.0,"anno":2024,"mes":9,"dia":10,"tag":""}],"color":"#ffeb3f84","tags":["indispensable","","compras","ocio"]}';

    Cuenta cuentaWeb = Cuenta.fromJson(await json.decode(jsonCuentaWeb));
    return [cuentaWeb];
  }

  Future getDatos(bool isWeb) async {
    if (isWeb) {
      Values().cuentas.value = await getDatosJson();
    }

    final snapshot = await ref.where('id', isEqualTo: user!.uid).get();
    List<Cuenta> ret = snapshot.docs
        .map((doc) => Cuenta.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    count = ret.length;

    Values().cuentas.value = ret;
  }

  void crearNuevaCuenta(
      String nombre, int posicion, String? color, bool isWeb) async {
    String documento = "${user!.uid}-$posicion";
    Cuenta c = Cuenta(
        Meses: RxList<Mes>(),
        Nombre: nombre.obs,
        id: user!.uid.obs,
        posicion: posicion.obs,
        color: (color ?? "#000000").obs,
        deudas: RxList<Gasto>(),
        fijos: RxList<Gasto>(),
        tags: RxList<String>());

    Values().cuentaRet.value = c;
    Values().cuentas.add(c);

    if (!isWeb) {
      await ref.doc(documento).set(c.toJson());
    }
  }

  Future almacenarDatos(Cuenta c, bool isWeb) async {
    if (!isWeb) {
      await ref.doc("${c.id}-${c.posicion}").update(c.toJson());
    }

    showToast(text: 'guardado correctamente');
  }

  Future deleteCuenta(Cuenta c, bool isWeb) async {
    if (!isWeb) {
      await ref.doc("${c.id}-${c.posicion}").delete();
    }
  }

  Future<Cuenta> importFromJson(
      Map<String, dynamic> json, int posicion, bool isWeb) async {
    String documento = "${user!.uid}-$posicion";
    Cuenta c = Cuenta.fromJson(json);
    c.id.value = user!.uid;
    c.posicion.value = posicion;

    if (!isWeb) {
      await ref.doc(documento).set(c.toJson());
    }

    return c;
  }
}
