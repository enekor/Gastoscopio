import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:flutter/material.dart';

class MovementFormScreen extends StatefulWidget {
  final MovementValue? movement;

  const MovementFormScreen({super.key, this.movement});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isExpense = true;
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

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final db = SqliteService().db;

    // Get or create month
    final month = await db.monthDao.findMonthByMonthAndYear(
      _selectedDate.month,
      _selectedDate.year,
    );

    final monthId = month?.id ?? await _createMonth(_selectedDate);

    // Get category    // Generate category if needed and not already set
    if (_category == null) {
      final generatedCategory = await GeminiService().generateCategory(
        _descriptionController.text,
        context,
      );

      if (generatedCategory.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo generar la categoría, puedes asignarla manualmente en el visionado de gastos',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Si el problema persiste, por favor revisa tu conexión a internet o la api key proporcionada en ajustes.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      _category = generatedCategory;
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
        _category,
      );
      await db.movementValueDao.insertMovementValue(movement);
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.movement != null
                ? 'Movimiento actualizado con éxito'
                : 'Movimiento guardado con éxito',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true); // Devolver true para indicar éxito
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
                  const SizedBox(height: 16),

                  // Botón de guardar
                  FilledButton(
                    onPressed: () => _saveMovement(context),
                    child: const Text('Guardar'),
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
