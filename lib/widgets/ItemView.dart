import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/Get.dart';

Widget ItemCard(String nombre,double ahorro, {required Function open, required Function delete}) {
  RxBool seleccionado = false.obs;
  RxString text = nombre.obs;

  return Obx(()=> InkWell(
      onTap: ()=>open(),
      onLongPress: ()=>seleccionado.value = !seleccionado.value,
      onSecondaryTap: ()=>seleccionado.value = !seleccionado.value,
    child: Card(
      child: Column(
        children: [
          const Icon(
            Icons.face,
            color: Colors.amber,
            size:50.0
          ),
          Text(text.value),
          Text("${ahorro.toStringAsFixed(2)}€"),
          seleccionado.value
            ?Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  flex:5,
                  child: IconButton(onPressed: () {
                    seleccionado.value = false;
                    open();
                  }, icon: const Icon(Icons.open_in_new_rounded)),
                ),
                Expanded(
                  flex:5,
                  child: IconButton(onPressed: () {
                    seleccionado.value = false;
                    text.value = "Borrado";
                    delete();
                  },icon: const Icon(Icons.delete)),
                )
              ],
            )
            :Container()
          ],
        )
      ),
    ),
  );
}

Widget CardButton({required Function onPressed, required Widget child})=>
  InkWell(
    onTap: ()=>onPressed(),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    ),
  );

Widget selectableSettingView<T>({required String title, required List<T> values, required Function(T) onSelected, required double width}){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(flex:3,child: Text(title)),
      Expanded(
        flex:7,
        child: DropdownButtonFormField(
          decoration: InputDecoration(
            constraints: BoxConstraints(maxWidth: width/4),
          ),
          items: values.map((value) => DropdownMenuItem(child: Text(value.toString()), value: value,)).toList(),
          onChanged: (value)=>onSelected(value!),
          value: values.first,
        )
      )
    ],
  );
}

Widget buttonSettingView({required String text, IconData? icono, required Function onTap}){
  return ElevatedButton(
    onPressed: ()=>onTap(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text),
        icono!=null
          ?Icon(icono)
          :Container()
      ],
    ),
  );
}

Widget switchSettingView({required Function(bool) onChange, required String text, required bool inicial}){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(text),
      Switch(value: inicial, onChanged: onChange)
    ],
  );
}

Widget redirectSettingView({required Function onTap, required String text}){
  return TextButton(onPressed: ()=>onTap(), child: Text(text));
}