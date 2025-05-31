import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/settings.dart/widgets/apikey-generator.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentCurrency = '€';

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.currency,
    );
    if (currency != null && mounted) {
      setState(() {
        _currentCurrency = currency;
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
        const SnackBar(content: Text('Moneda actualizada correctamente')),
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
