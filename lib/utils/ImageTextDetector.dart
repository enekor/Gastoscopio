import 'dart:convert';
import 'dart:io';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils/TextRecognitionApi.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;

Future<Map<List<String>, List<double>>> extractInformationFromImage(
    File imageFile) async {
  String text = await TextRecognitionApi.recognizeText(imageFile);

  //sacar los numeros y ponerlos en un MiniItemView, y guardar un diccionario de
  //textos sacados de la imagen, para poder ponerle un nombre custom a cada valor o uno sacado de la foto

  var datos = separateTextAndNumbers(text);

  return datos;
}

Map<List<String>, List<double>> separateTextAndNumbers(String text) {
  final textWithoutEuro = text.replaceAll('€', '');
  final words = <String>[];
  final numbers = <double>[];

  textWithoutEuro.split(' ').forEach((word) {
    final number = double.tryParse(word);
    if (number != null) {
      numbers.add(number);
    } else {
      words.add(word);
    }
  });

  return {words: numbers};
}
