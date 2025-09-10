import 'package:flutter/material.dart';

Widget Loading(BuildContext context, {String? text}) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (text != null) ...[
        Text(text, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 25),
      ],
      Image.asset("assets/loading/loading.gif"),
    ],
  ),
);
