import 'package:flutter/material.dart';

void Loading(BuildContext context, {String? text}) {
  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (text != null) ...[
          Text(text, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 25),
        ],
        Image.asset(
          "loading/loading.gif",
          height: MediaQuery.sizeOf(context).width / 2,
          width: MediaQuery.sizeOf(context).width / 2,
        ),
      ],
    ),
  );
}
