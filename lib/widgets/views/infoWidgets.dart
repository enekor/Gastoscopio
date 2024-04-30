import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

RxBool editarIngreso = false.obs;
List<Widget> GetGastos({required List<Mes> meses, required String mes, required Function(String,double) onSave, required Function(String,double) onDelete,required Function(int) onSelect, required Function onIWTap, required ThemeData theme}) {
    List<Widget> ret = [];
    int contador = 0;

    meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value).first.Gastos.forEach((gasto) {
      if (gasto.valor > 0) {
        ret.add( gastoView(
          onSave,
          onDelete,
          onSelect,
          gasto.nombre,
          gasto.valor,
          contador,
          theme
          )
        );
      }
      contador++;
    });

    ret.add(Padding(
      padding: const EdgeInsets.all(30.0),
      child: InkWell(
        onTap: ()=>onIWTap(),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text("Extras"),
              Text("${meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value).first.GetExtras().toStringAsFixed(2)}€")
            ],
          ),
        ),
      ),
    ));

    contador++;
    return ret;
  }

  List<Widget> GetIngresos({required List<Mes> meses, required String mes, required Function(String,double) onSave, required Function(String,double) onDelete,required Function(int) onSelected, required Function onIWTap, required ThemeData theme}) {
    List<Widget> ret = [];
    int contador = 0;

    meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value).first.Gastos.forEach((gasto) {
      if (gasto.valor < 0) {
        ret.add( gastoView(
          onSave,
          onDelete,
          onSelected,
          gasto.nombre,
          gasto.valor * -1,
          contador,
          theme
          )
        );
      }
      contador++;
    });

    contador++;
    return ret;
  }

  Widget appBarMesExists({required double width, required String mes,required Cuenta c}){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width * 0.5,
                child: Card(
                    child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    Text(mes),
                    Text("${c.Meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value).first.GetAhorros().toStringAsFixed(2)}€")
                  ],
                )),
              ),
              SizedBox(
                width: width * 0.6,
                child: Card(
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(c.Nombre),
                        Text("${c.GetTotal(Values().anno.value).toStringAsFixed(2)}€")
                    ])),
              )
            ],
        )
      ],
    );
  }

  Widget bodyMesExists({required ThemeData theme,required String mes, required BuildContext context,  required Rx<Cuenta> cuenta,required Function(int) onSelected, required List<Gasto> deleted, required Function(String) onSelecMes, required Function(bool) onIngresoGastosPressed}){
    
    return Obx(()=>Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //selector de meses
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: DropdownButtonFormField(
              dropdownColor: theme.primaryColor,
              decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  fillColor:
                      theme.primaryColor),
              value: mes,
              items: Values().nombresMes.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (item) {
                mes = item.toString();
                Values().ChangeMes(mes);
                onSelecMes(mes);
              },
            ),
          ),
          //selector de gastos/ingresos
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //ingresos
              Expanded(
                flex: 5,
                child: InkWell(
                  onTap: ()=>onIngresoGastosPressed(true),
                  child: Card(
                    color: theme.brightness == Brightness.dark
                      ?AppColorsD.okButtonColor
                      :AppColorsL.okButtonColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text("Ingresos"),
                        Text("${cuenta.value.Meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value).first.GetIngresos().toStringAsFixed(2)}€")
                      ],
                    ),
                  ),
                ),
              ),
              //gastos
              Expanded(
                flex: 5,
                child: InkWell(
                  child: Card(
                    color: theme.brightness == Brightness.dark
                      ? AppColorsD.errorButtonColor
                      :AppColorsL.errorButtonColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text("Gastos"),
                        Text("${cuenta.value.Meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value).first.GetGastos().toStringAsFixed(2)}€")
                      ],
                    ),
                  ),
                  onTap: ()=>onIngresoGastosPressed(false)
                )
              )
            ]
          ),
        ],
      ),
    );
  }

  Widget bodyMesNotExists({required String mes, required Function(String,double) onNuevoIngreso, required Function(String,double) onCrearMes, required ThemeData theme}){

    TextEditingController controller = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.network(
          "https://cdn.icon-icons.com/icons2/1632/PNG/512/62878dollarbanknote_109277.png",
          height: 100,
          width: 100,
        ),
        const SizedBox(height: 80),
        Text("¿Cuanto se ha ingresado en ${mes}?"),
        const SizedBox(
          height: 10,
        ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Ingreso para ${mes}"),
        ),
        const SizedBox(
          height: 10,
        ),
        IconButton(
          onPressed: ()=>onCrearMes(mes,double.parse(controller.text)),
          icon: const Icon(Icons.check),
          color: theme.brightness == Brightness.dark
            ? AppColorsD.okButtonColor
            : AppColorsL.okButtonColor
        )
        ]
    );
  }

BottomNavigationBar navigationBar({required Function onDeudas, required Function onRecurrentes, required Function onSummary, required ThemeData theme}){
  bool oscuro = theme.brightness != Brightness.light;
  void onTap(int pos){
    switch (pos) {
      case 0:
        onSummary();
        break;
      case 1:
        onRecurrentes();
        break;
      case 2:
        onDeudas();
        break;
      default:
    }
  }

  return BottomNavigationBar(
    selectedLabelStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
    unselectedLabelStyle: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
    elevation: 0,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.summarize,color: Colors.black87,), label: "Resumen"),
      BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.moneyCheckDollar,color: Colors.black87), label: "Recurrentes"),
      BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.handHoldingDollar,color: Colors.black87),label: "Deudas")
    ],
    onTap: onTap,
    currentIndex: 0,
    backgroundColor: oscuro?AppColorsL.secondaryColor5:AppColorsD.secondaryColor5,
    showUnselectedLabels: true,
    showSelectedLabels: true,
  );
}