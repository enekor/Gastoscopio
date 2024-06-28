import 'package:flutter/material.dart';

void showYesNoDialog(
    {required String title,
    String yesButton = "Ok",
    String noButton = "Cancelar",
    required Function onYes,
    required BuildContext context,
    required Widget body,
    Function? onCancel}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: body,
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              onYes();
            },
            child: Text(yesButton)),
        TextButton(
            onPressed: () {
              if (onCancel != null) onCancel();
              Navigator.pop(context);
            },
            child: Text(noButton)),
      ],
    ),
  );
}
