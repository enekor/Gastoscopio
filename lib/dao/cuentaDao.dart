import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class cuentaDao {
  CollectionReference ref = FirebaseFirestore.instance.collection('cuenta');
  User? user = Auth().currentUser ?? null;
  static int count = 0;

  Future obtenerDatos() async {
    /*
    final snapshot = await ref.get();
    Values().cuentas = snapshot.docs.map((doc) => Cuenta.fromJson(doc.data() as Map<String, dynamic>)).toList();
    */

    /*if(Values().cuentas.isEmpty){
      for(int i = 1;i<3;i++){
        Values().cuentas.add( Cuenta(
          id: i,
          Meses: [],
          Nombre: "nombre$i"
        ));
      }
    }*/
  }

  Future<List<Cuenta>> getDatos() async {
    /*return List.generate(2, (index) => Cuenta(
      id: math.Random().nextDouble().toString(),
      Meses: [],
      Nombre: "nombre${index+1}",
      posicion: index+1
    ));
    */

    print(user);
    final snapshot = await ref.where('id', isEqualTo: user!.uid).get();
    List<Cuenta> ret = snapshot.docs
        .map((doc) => Cuenta.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    count = ret.length;
    return ret;
  }

  Future migrardatos() async {
    var snapshot = await ref.get();
    List<Cuenta> datos = snapshot.docs
        .map((doc) => Cuenta.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    int contador = 1;

    for (Cuenta c in datos) {
      c.id.value = user!.uid;
      c.posicion.value = contador;

      String doc = "${c.id}-${c.posicion}";
      ref.doc(doc).set(c.toJson());
      contador++;
    }
  }

  Future<Cuenta> crearNuevaCuenta(
      String nombre, int posicion, String? color) async {
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

    await ref.doc(documento).set(c.toJson());

    return c;
  }

  Future almacenarDatos(Cuenta c) async {
    await ref.doc("${c.id}-${c.posicion}").update(c.toJson());
    
      showToast(text: 'guardado correctamente');
  }

  Future deleteCuenta(Cuenta c) async {
    await ref.doc("${c.id}-${c.posicion}").delete();
  }

  Future<Cuenta> importFromJson(Map<String, dynamic> json, int posicion) async {
    String documento = "${user!.uid}-$posicion";
    Cuenta c = Cuenta.fromJson(json);
    c.id.value = user!.uid;
    c.posicion.value = posicion;

    await ref.doc(documento).set(c.toJson());

    return c;
  }
}
