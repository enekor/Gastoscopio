import 'package:carousel_slider/carousel_slider.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyGenerator extends StatefulWidget {
  const ApiKeyGenerator({super.key});

  @override
  State<ApiKeyGenerator> createState() => _ApiKeyGeneratorState();
}

class _ApiKeyGeneratorState extends State<ApiKeyGenerator> {
  final TextEditingController _apiKeyController = TextEditingController();
  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.apiKey,
    );
    if (apiKey != null && mounted) {
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _saveApiKey() async {
    if (_isSaving) return;

    final apiKeyText = _apiKeyController.text.trim();

    // Solo validar que no esté vacío
    if (apiKeyText.isEmpty) {
      Fluttertoast.showToast(
        msg: "❌ El API Key no puede estar vacío",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Simplemente guardar en SharedPreferences
      await SharedPreferencesService().setStringValue(
        SharedPreferencesKeys.apiKey,
        apiKeyText,
      );

      if (mounted) {
        // Mostrar éxito y aviso de reinicio
        Fluttertoast.showToast(
          msg: "✅ API Key guardada correctamente",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Mostrar diálogo para reiniciar la aplicación
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('API Key Guardada'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu API Key se ha guardado correctamente.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'IMPORTANTE: Para que la IA funcione correctamente, debes reiniciar completamente la aplicación.',
                  ),
                  SizedBox(height: 8),
                  Text(
                    '💡 Cierra la app completamente y vuelve a abrirla.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Error al guardar
      if (mounted) {
        Fluttertoast.showToast(
          msg: "❌ Error al guardar API Key",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Error al guardar API Key',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildCarouselItem(String imagePath, String caption) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Para activar las funciones de inteligencia artificial, necesitas obtener una clave API de Google. Te guiamos paso a paso:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 300,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 280,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                  autoPlay: false,
                  pageSnapping: true,
                  padEnds: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: [
                  _buildCarouselItem(
                    'assets/guide/step1.jpg',
                    '1. Accede a Google AI Studio e inicia sesión con tu cuenta',
                  ),
                  _buildCarouselItem(
                    'assets/guide/step2.jpg',
                    '2. Haz clic en "Crear clave de API" y copia la clave generada',
                  ),
                  _buildCarouselItem(
                    'assets/guide/step2b.jpg',
                    '2.1. Si aparece esta ventana emergente, ciérrala con la X',
                  ),
                  _buildCarouselItem(
                    'assets/guide/step2c.jpg',
                    '2.2. Desplázate hacia abajo hasta encontrar la tabla de claves',
                  ),
                  _buildCarouselItem(
                    'assets/guide/step2d.jpg',
                    '2.3. Haz clic en el enlace azul para acceder a la clave',
                  ),
                  _buildCarouselItem(
                    'assets/guide/step3.jpg',
                    '3. Pega la clave API en el campo de texto de la aplicación',
                  ),
                  _buildCarouselItem(
                    'assets/guide/step4.jpg',
                    '4. Presiona el botón guardar para completar la configuración',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                (index) => Container(
                  width: 10.0,
                  height: 10.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentIndex == index
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(45)
                            : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed:
                    () =>
                        _launchUrl('https://makersuite.google.com/app/apikey'),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ir a Google AI Studio'),
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'Clave API de Google',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.save),
                    onPressed:
                        _isSaving
                            ? null
                            : () async {
                              await _saveApiKey();
                            },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
