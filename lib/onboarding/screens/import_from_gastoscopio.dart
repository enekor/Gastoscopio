import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/json_import_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:flutter/material.dart';

class ImportFromGastoscopioScreen extends StatefulWidget {
  final Function(JsonImportResult?) onImportSuccess;

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
          title: Text('¡Archivo procesado!'),
          content: Text(
            'El archivo "${result.fileName}" se ha analizado correctamente:\n\n'
            '• ${result.months.length} meses encontrados\n'
            '• ${result.movements.length} movimientos procesados\n\n'
            'A continuación verás una vista previa de los datos. '
            'Revísalos y haz clic en "Importar Datos" para completar la importación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Revisar datos'),
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
    if (_importResult != null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _importResult = null;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Vista previa de la importación',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResultsList(_importResult!)),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Tienes datos de una exportación anterior?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Puedes importar datos desde un archivo JSON exportado anteriormente.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _handleFileSelection,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Seleccionar archivo JSON'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      widget.onImportSuccess(null);
                    },
                    child: const Text('No tengo datos para importar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(JsonImportResult result) {
    // Group movements by month
    final movementsByMonth = <String, List<MovementValue>>{};
    for (var movement in result.movements) {
      // Encontramos el mes por posición en la lista en lugar de por ID
      final monthIndex =
          movement.monthId - 1; // Los IDs temporales empiezan en 1
      if (monthIndex < 0 || monthIndex >= result.months.length) {
        continue; // Skip invalid monthId
      }
      final month = result.months[monthIndex];
      final key = '${month.month}/${month.year}';
      if (!movementsByMonth.containsKey(key)) {
        movementsByMonth[key] = [];
      }
      movementsByMonth[key]!.add(movement);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de la importación',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Archivo: ${result.fileName}'),
                      Text('Períodos: ${result.months.length} meses'),
                      Text('Movimientos totales: ${result.movements.length}'),
                      Row(
                        children: [
                          Text('Total de ingresos: '),
                          Text(
                            '${result.movements.where((m) => !m.isExpense).fold<double>(0, (sum, m) => sum + m.amount).toStringAsFixed(2)}$_moneda',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Total de gastos: '),
                          Text(
                            '${result.movements.where((m) => m.isExpense).fold<double>(0, (sum, m) => sum + m.amount).toStringAsFixed(2)}$_moneda',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Movements by Month
              ...movementsByMonth.entries
                  .map(
                    (entry) => Card(
                      child: ExpansionTile(
                        title: Text(entry.key),
                        subtitle: Text('${entry.value.length} movimientos'),
                        children:
                            entry.value.map((movement) {
                              final gastos = entry.value
                                  .where((m) => m.isExpense)
                                  .fold<double>(0, (sum, m) => sum + m.amount);
                              final ingresos = entry.value
                                  .where((m) => !m.isExpense)
                                  .fold<double>(0, (sum, m) => sum + m.amount);

                              return Column(
                                children: [
                                  if (movement == entry.value.first)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total ingresos: ${ingresos.toStringAsFixed(2)}$_moneda',
                                            style: const TextStyle(
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            'Total gastos: ${gastos.toStringAsFixed(2)}$_moneda',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ListTile(
                                    title: Text(movement.description),
                                    subtitle: Text(
                                      'Día: ${movement.day} | '
                                      'Categoría: ${movement.category ?? "Sin categoría"}',
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${movement.amount.toStringAsFixed(2)}$_moneda',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                movement.isExpense
                                                    ? Colors.red
                                                    : Colors.green,
                                          ),
                                        ),
                                        Text(
                                          movement.isExpense
                                              ? 'Gasto'
                                              : 'Ingreso',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                movement.isExpense
                                                    ? Colors.red
                                                    : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _importResult = null;
                  });
                },
                icon: Icon(Icons.close),
                label: Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onImportSuccess(result),
                icon: Icon(Icons.check),
                label: Text('Importar Datos'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
