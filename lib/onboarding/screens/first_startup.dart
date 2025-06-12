import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class FirstStartupScreen extends StatefulWidget {
  const FirstStartupScreen({Key? key, required this.onTermsAccepted})
    : super(key: key);

  final Future<void> Function() onTermsAccepted;

  @override
  State<FirstStartupScreen> createState() => _FirstStartupScreenState();
}

class _FirstStartupScreenState extends State<FirstStartupScreen> {
  bool _hasScrolledToBottom = false;
  final ScrollController _scrollController = ScrollController();
  String _termsContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTermsFromAssets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTermsFromAssets() async {
    try {
      final content = await rootBundle.loadString(
        'assets/terminos-y-condiciones.md',
      );
      setState(() {
        _termsContent = content;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback a texto estático si hay error cargando el archivo
      setState(() {
        _termsContent = _fallbackTermsText;
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
          style: GoogleFonts.pacifico(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Bienvenido a Gastoscopio!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor, lee y acepta los términos de uso para continuar:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Markdown(
                          controller: _scrollController,
                          data: _termsContent,
                          padding: const EdgeInsets.all(16),
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14, height: 1.5),
                            h1: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            blockquote: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_hasScrolledToBottom)
              const Text(
                'Desplázate hasta el final para habilitar los botones',
                style: TextStyle(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    exit(0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rechazar y Salir'),
                ),
                ElevatedButton(
                  onPressed:
                      _hasScrolledToBottom
                          ? () async {
                            await widget.onTermsAccepted();
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _hasScrolledToBottom ? Colors.green : Colors.grey,
                  ),
                  child: const Text('Aceptar y Continuar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

const String _fallbackTermsText =
    '''# TÉRMINOS Y CONDICIONES DE USO - Gastoscopio

**Última actualización:** Junio 2025

Al utilizar la aplicación Gastoscopio, usted acepta estos términos y condiciones de uso.

Gastoscopio es una aplicación de gestión financiera personal que utiliza su cuenta de Google para autenticación y almacenamiento seguro en Google Drive.

La aplicación requiere una API Key de Google Gemini para análisis inteligentes. Esta clave se almacena localmente en su dispositivo.

**Responsabilidad de IA:** Las recomendaciones generadas por IA no constituyen asesoría financiera profesional.

**Privacidad:** No recopilamos información personal. Sus datos se almacenan localmente y en su Google Drive personal.

Al continuar, acepta estos términos en su totalidad.
''';
