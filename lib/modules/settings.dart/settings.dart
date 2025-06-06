import 'package:carousel_slider/carousel_slider.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/settings.dart/widgets/apikey-generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:svg_flutter/svg.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentCurrency = '€';
  bool _isSvg = false;
  int _r = 255;
  int _g = 255;
  int _b = 255;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currency = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.currency,
    );
    if (currency != null && mounted) {
      setState(() {
        _currentCurrency = currency;
      });
    }

    final isSvg = await SharedPreferencesService().getBoolValue(
      SharedPreferencesKeys.isSvgAvatar,
    );
    if (isSvg != null && mounted) {
      setState(() {
        _isSvg = isSvg;
      });
    }

    final avatarColor = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.avatarColor,
    );
    if (avatarColor != null && mounted) {
      setState(() {
        _r = int.tryParse(avatarColor.split(",")[0]) ?? 255;
        _g = int.tryParse(avatarColor.split(",")[1]) ?? 255;
        _b = int.tryParse(avatarColor.split(",")[2]) ?? 255;
      });
    }
  }

  Future<void> _saveCurrency(String currency) async {
    await SharedPreferencesService().setStringValue(
      SharedPreferencesKeys.currency,
      currency,
    );
    if (mounted) {
      setState(() {
        _currentCurrency = currency;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moneda actualizada correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveLogo() async {
    await SharedPreferencesService().setBoolValue(
      SharedPreferencesKeys.isSvgAvatar,
      _isSvg,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo actualizado correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveAvatarColor(int r, int g, int b) async {
    await SharedPreferencesService().setStringValue(
      SharedPreferencesKeys.avatarColor,
      '$r,$g,$b',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Color de avatar actualizado correctamente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración General',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moneda',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _currentCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        items: const [
                          DropdownMenuItem(value: '€', child: Text('Euro (€)')),
                          DropdownMenuItem(
                            value: '\$',
                            child: Text('Dólar (\$)'),
                          ),
                          DropdownMenuItem(
                            value: '£',
                            child: Text('Libra (£)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _saveCurrency(value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Logo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: Row(
                              children: [
                                Expanded(
                                  child: CarouselSlider(
                                    options: CarouselOptions(
                                      height: 100,
                                      viewportFraction: 0.9,
                                      enlargeCenterPage: true,
                                      enableInfiniteScroll: false,
                                      autoPlay: false,
                                      pageSnapping: true,
                                      padEnds: true,
                                      onPageChanged: (index, reason) {
                                        setState(() {
                                          _isSvg = index == 1;
                                        });
                                        _saveLogo();
                                      },
                                    ),
                                    items: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.asset(
                                            'assets/logo.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.outline,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/logo.svg',
                                                width: 80,
                                                height: 80,
                                                colorFilter: ColorFilter.mode(
                                                  Color.fromARGB(
                                                    255,
                                                    _r,
                                                    _g,
                                                    _b,
                                                  ),
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          'Selecciona un color',
                                                        ),
                                                        content: SingleChildScrollView(
                                                          child: ColorPicker(
                                                            pickerColor:
                                                                Color.fromARGB(
                                                                  255,
                                                                  _r,
                                                                  _g,
                                                                  _b,
                                                                ),
                                                            onColorChanged: (
                                                              Color color,
                                                            ) {
                                                              setState(() {
                                                                _r = color.red;
                                                                _g =
                                                                    color.green;
                                                                _b = color.blue;
                                                              });
                                                            },
                                                            pickerAreaHeightPercent:
                                                                0.8,
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            child: const Text(
                                                              'Cancelar',
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                          ),
                                                          TextButton(
                                                            child: const Text(
                                                              'Aceptar',
                                                            ),
                                                            onPressed: () {
                                                              _saveAvatarColor(
                                                                _r,
                                                                _g,
                                                                _b,
                                                              );
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.outline,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        Color.fromARGB(
                                                          255,
                                                          _r,
                                                          _g,
                                                          _b,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'API Key de Google AI Studio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const ApiKeyGenerator(),
            ],
          ),
        ),
      ),
    );
  }
}
