import 'package:carousel_slider/carousel_slider.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeyGenerator extends StatefulWidget {
  const ApiKeyGenerator({super.key});

  @override
  State<ApiKeyGenerator> createState() => _ApiKeyGeneratorState();
}

class _ApiKeyGeneratorState extends State<ApiKeyGenerator> {
  final TextEditingController _apiKeyController = TextEditingController();
  int _currentIndex = 0;

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
      child: Column(
        children: [
          const Text(
            'Para usar la aplicación, necesitas una API Key de Google AI Studio. Sigue estos pasos:',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
                  '1. Ve a Google AI Studio inicia sesión y seleciona "Crear clave de api',
                ),
                _buildCarouselItem(
                  'assets/guide/step2.jpg',
                  '2. Dale al boton de copiar para copiar la API Key, si te da una pantalla diferente ve al siguiente paso, si no, ve al paso 3',
                ),
                _buildCarouselItem(
                  'assets/guide/step2b.jpg',
                  '2.1. Si te sale la pantalla como esta dale a la X para cerrar la ventana y vuelve a la pantalla anterior',
                ),
                _buildCarouselItem(
                  'assets/guide/step2c.jpg',
                  '2.2. Haz scroll hacia abajo hasta que veas una tabla',
                ),
                _buildCarouselItem(
                  'assets/guide/step2d.jpg',
                  '2.3. Selecciona el texto azul y verás el recuadro del paso 2 para poder seguirlo',
                ),
                _buildCarouselItem(
                  'assets/guide/step3.jpg',
                  '3. Pega la API Key en la barra de texto de la app',
                ),
                _buildCarouselItem(
                  'assets/guide/step4.jpg',
                  '4. Dale al boton de guardar',
                ),
                _buildCarouselItem('assets/guide/step5.jpg', ''),
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
                          ? Theme.of(context).colorScheme.primary.withAlpha(45)
                          : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed:
                  () => _launchUrl('https://makersuite.google.com/app/apikey'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Obtener API Key'),
            ),
          ),
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await SharedPreferencesService().setStringValue(
                      SharedPreferencesKeys.apiKey,
                      _apiKeyController.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('API Key guardada correctamente'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
