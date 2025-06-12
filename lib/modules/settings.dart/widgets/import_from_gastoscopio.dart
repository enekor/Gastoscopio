import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/json_import_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:flutter/material.dart';

class ImportFromGastoscopioScreen extends StatefulWidget {
  final Function(Map<String, dynamic> result) onImportSuccess;

  const ImportFromGastoscopioScreen({Key? key, required this.onImportSuccess})
    : super(key: key);

  @override
  _ImportFromGastoscopioScreenState createState() =>
      _ImportFromGastoscopioScreenState();
}

class _ImportFromGastoscopioScreenState
    extends State<ImportFromGastoscopioScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _importResult;
  late String _moneda;

  @override
  void initState() {
    super.initState();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );
  }

  Future<void> _handleFileSelection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await JsonImportService.selectAndProcessJsonFile();

      setState(() {
        _importResult = result;
        _isLoading = false;
      });

      if (result != null) {
        _showSuccessDialog(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¡Éxito!'),
          content: Text(
            'Archivo procesado correctamente:\n'
            '• ${result['Months']?.length ?? 0} meses encontrados\n'
            '• ${result['Movements']?.length ?? 0} movimientos procesados\n'
            '• ${result['FixedMovements']?.length ?? 0} movimientos fijos procesados\n'
            'Por favor, reinicie la aplicacion para ver los cambios.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.onImportSuccess(result);
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Card
        Card(
          color: Theme.of(context).colorScheme.secondary.withAlpha(25),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.file_upload, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Seleccionar archivo JSON',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Column(
                  children: [
                    Text(
                      'Para importar datos desde Gastoscopio, sigue estos pasos:',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. En Gastoscopio, ve a Ajustes y usa la opción "Exportar datos"\n'
                      '2. El archivo JSON se guardará en la carpeta Descargas\n'
                      '3. Pulsa el botón "Buscar archivos JSON" abajo para importar',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Import Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleFileSelection,
                  icon:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Icon(Icons.folder_open),
                          ),
                  label: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      _isLoading ? 'Procesando...' : 'Seleccionar archivo JSON',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
