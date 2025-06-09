import 'package:cashly/modules/settings.dart/widgets/apikey-generator.dart';
import 'package:flutter/material.dart';

class ApiKeySetupScreen extends StatefulWidget {
  final VoidCallback onApiKeySet;

  const ApiKeySetupScreen({Key? key, required this.onApiKeySet})
    : super(key: key);

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configura tu API Key de Gemini',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'La API Key es necesaria para utilizar las funciones de IA.\n'
              'Es gratis y fácil de obtener.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Card(
              color: Color.fromRGBO(3, 218, 198, 25),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ApiKeyGenerator(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.onApiKeySet,
              child: const Text('Continuar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
