import 'package:fluttertoast/fluttertoast.dart';

void showToast({required String text, Toast length = Toast.LENGTH_SHORT, ToastGravity posicion = ToastGravity.CENTER, int timeForWebIos = 1}){
  Fluttertoast.showToast(
        msg: text,
        toastLength: length,
        gravity: posicion,
        timeInSecForIosWeb: timeForWebIos,
      );
}