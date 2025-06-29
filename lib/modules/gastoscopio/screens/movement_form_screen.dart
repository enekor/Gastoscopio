import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MovementFormScreen extends StatefulWidget {
  final MovementValue? movement;

  const MovementFormScreen({super.key, this.movement});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isExpense = true;
  bool _isLoading = false; // Agregar indicador de carga
  late final _descriptionController = TextEditingController();
  late final _amountController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  late String _moneda = 'loading...';
  String? _category;

  @override
  void initState() {
    super.initState();
    if (widget.movement != null) {
      _descriptionController.text = widget.movement!.description;
      _amountController.text = widget.movement!.amount.toStringAsFixed(2);
      _isExpense = widget.movement!.isExpense;
      _selectedDate = DateTime.now().copyWith(day: widget.movement!.day);
      _category = widget.movement!.category;
    }
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<int> _createMonth(DateTime date) async {
    final db = SqliteService().db;
    final newMonth = Month(date.month, date.year);
    await db.monthDao.insertMonth(newMonth);
    final month = await db.monthDao.findMonthByMonthAndYear(
      date.month,
      date.year,
    );
    return month!.id!;
  }

  Future<void> _saveMovement(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    // Prevenir múltiples guardados
    if (_isLoading) return;

    // Cerrar el teclado para mejorar la experiencia del usuario
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });
    try {
      // Parseo más robusto del monto
      String amountText = _amountController.text.trim();
      // Reemplazar comas por puntos para formato decimal
      amountText = amountText.replaceAll(',', '.');
      // Eliminar espacios
      amountText = amountText.replaceAll(' ', '');
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        if (mounted) {
          // Toast inmediato
          Fluttertoast.showToast(
            msg: "❌ Monto inválido",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por favor, introduce un monto válido mayor que 0',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final db = SqliteService().db;

      // Get or create month
      final month = await db.monthDao.findMonthByMonthAndYear(
        _selectedDate.month,
        _selectedDate.year,
      );

      final monthId =
          month?.id ??
          await _createMonth(
            _selectedDate,
          ); // Generate category if needed and not already set
      if (_category == null) {
        try {
          // Agregar timeout para evitar que se quede colgado
          final generatedCategory = await GeminiService()
              .generateCategory(_descriptionController.text, context)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  return ''; // Retornar categoría vacía si hay timeout
                },
              );

          if (generatedCategory.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se pudo generar la categoría, se guardará con categoría vacía. Puedes asignarla manualmente más tarde.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          _category = generatedCategory.isEmpty ? '' : generatedCategory;
        } catch (e) {
          // Si falla la generación de categoría, usar categoría vacía
          _category = '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error al generar categoría. Se guardará sin categoría.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      final MovementValue movement;
      if (widget.movement != null) {
        // Update existing movement
        movement = MovementValue(
          widget.movement!.id,
          monthId,
          _descriptionController.text,
          amount,
          _isExpense,
          _selectedDate.day,
          _category,
        );
        await db.movementValueDao.updateMovementValue(movement);
      } else {
        // Create new movement
        movement = MovementValue(
          DateTime.now().millisecondsSinceEpoch, // Unique ID based on timestamp
          monthId,
          _descriptionController.text,
          amount,
          _isExpense,
          _selectedDate.day,
          _category?.trim(),
        );
        await db.movementValueDao.insertMovementValue(movement);
      }

      // Call haveToUpload() after any movement creation or update
      await SharedPreferencesService().haveToUpload();

      // Update FinanceService singleton
      if (mounted) {
        final financeService = FinanceService.getInstance(
          db.monthDao,
          db.movementValueDao,
          db.fixedMovementDao,
        );
        await financeService.updateSelectedDate(
          _selectedDate.month,
          _selectedDate.year,
        );
        // Mostrar toast de éxito
        Fluttertoast.showToast(
          msg:
              widget.movement != null
                  ? "✅ Movimiento actualizado"
                  : "✅ Movimiento guardado",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.movement != null
                      ? 'Movimiento actualizado con éxito'
                      : 'Movimiento guardado con éxito',
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, true); // Devolver true para indicar éxito
      }
    } catch (e) {
      // Manejo de errores específicos con mensajes informativos
      String errorMessage = 'Error desconocido';
      String errorType = 'Error general';

      if (e.toString().contains('database')) {
        errorType = 'Error de base de datos';
        errorMessage =
            'No se pudo acceder a la base de datos. Verifica que tengas espacio suficiente en el dispositivo.';
      } else if (e.toString().contains('parse') ||
          e.toString().contains('format')) {
        errorType = 'Error de formato';
        errorMessage =
            'El formato del monto no es válido. Usa números con punto o coma como decimal.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorType = 'Error de conexión';
        errorMessage =
            'Sin conexión a internet. El movimiento se guardará sin categoría automática.';
      } else if (e.toString().contains('permission')) {
        errorType = 'Error de permisos';
        errorMessage =
            'La aplicación no tiene permisos para guardar datos. Verifica los permisos de la app.';
      } else if (e.toString().contains('space') ||
          e.toString().contains('storage')) {
        errorType = 'Error de almacenamiento';
        errorMessage =
            'No hay suficiente espacio de almacenamiento en el dispositivo.';
      } else {
        errorType = 'Error inesperado';
        errorMessage = 'Ocurrió un error inesperado: ${e.toString()}';
      }

      if (mounted) {
        // Mostrar toast para feedback inmediato
        Fluttertoast.showToast(
          msg: "❌ $errorType",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Mostrar SnackBar con información detallada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      errorType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(errorMessage, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                      child: const Text(
                        'Entendido',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isExpense ? 'Nuevo Gasto' : 'Nuevo Ingreso',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Selector de tipo de movimiento
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Gasto'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Ingreso'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {_isExpense},
                    onSelectionChanged: (Set<bool> selection) {
                      setState(() {
                        _isExpense = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de monto
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      border: const OutlineInputBorder(),
                      suffixText: _moneda,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un monto';
                      }
                      if (double.tryParse(value.replaceAll(',', '.')) == null) {
                        return 'Por favor ingrese un monto válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selector de fecha
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Fecha: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                  const SizedBox(height: 16), // Botón de guardar
                  FilledButton(
                    onPressed: _isLoading ? null : () => _saveMovement(context),
                    child:
                        _isLoading
                            ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Guardando...'),
                              ],
                            )
                            : const Text('Guardar'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
