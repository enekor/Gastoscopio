import 'package:cashly/data/services/json_import_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:flutter/material.dart';

class ImportFromGastoscopioScreen extends StatefulWidget {
  final Function(JsonImportResult) onImportSuccess;

  const ImportFromGastoscopioScreen({Key? key, required this.onImportSuccess})
    : super(key: key);

  @override
  _ImportFromGastoscopioScreenState createState() =>
      _ImportFromGastoscopioScreenState();
}

class _ImportFromGastoscopioScreenState
    extends State<ImportFromGastoscopioScreen> {
  bool _isLoading = false;
  JsonImportResult? _importResult;
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

  void _showSuccessDialog(JsonImportResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¡Éxito!'),
          content: Text(
            'Archivo "${result.fileName}" procesado correctamente:\n'
            '• ${result.months.length} meses encontrados\n'
            '• ${result.movements.length} movimientos procesados',
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Importar Datos JSON'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
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
                    Text(
                      'Selecciona un archivo JSON para importar tus datos de meses y movimientos',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 16),
                    if (_importResult != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Último archivo: ${_importResult!.fileName}',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),
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
                      : Icon(Icons.folder_open),
              label: Text(
                _isLoading ? 'Procesando...' : 'Seleccionar Archivo JSON',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            // Skip Import Button
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: const Text('No tengo datos para importar'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 20),

            // Results Display
            if (_importResult != null) ...[
              Text(
                'Datos Procesados:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 10),
              Expanded(child: _buildResultsList(_importResult!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(JsonImportResult result) {
    return ListView(
      children: [
        // Meses Card
        Card(
          child: ExpansionTile(
            title: Text('Meses (${result.months.length})'),
            children:
                result.months.map((month) {
                  return ListTile(
                    title: Text('Mes ${month.month}/${month.year}'),
                    subtitle: Text('ID: ${month.id}'),
                  );
                }).toList(),
          ),
        ),

        // Movimientos Card
        Card(
          child: ExpansionTile(
            title: Text('Movimientos (${result.movements.length})'),
            children:
                result.movements.map((movement) {
                  return ListTile(
                    title: Text(movement.description),
                    subtitle: Text(
                      'Mes ID: ${movement.monthId} | Día: ${movement.day} | '
                      'Categoría: ${movement.category ?? "Sin categoría"}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${movement.amount.toStringAsFixed(2)}${_moneda}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                movement.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        Text(
                          movement.isExpense ? 'Gasto' : 'Ingreso',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                movement.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),

        ElevatedButton(
          onPressed: () => widget.onImportSuccess(result),
          child: Text(
            'Importar Datos',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
