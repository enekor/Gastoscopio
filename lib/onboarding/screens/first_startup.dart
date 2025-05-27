import 'dart:io';

import 'package:flutter/material.dart';

class FirstStartupScreen extends StatelessWidget {
  const FirstStartupScreen({Key? key, required this.onTermsAccepted})
    : super(key: key);

  final Function onTermsAccepted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),

          const Icon(Icons.rocket_launch, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            '¡Bienvenido a Cashly!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Antes de empezar, lee y acepta los terminos de uso de la aplicación.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  exit(0);
                },
                child: const Text('Rechazar'),
              ),
              ElevatedButton(
                onPressed: () => onTermsAccepted(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
