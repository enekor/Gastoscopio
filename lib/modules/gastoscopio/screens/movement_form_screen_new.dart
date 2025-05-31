import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MovementFormScreen extends StatefulWidget {
  const MovementFormScreen({super.key});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isExpense = true;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late String _moneda = 'loading...';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  Future<void> _saveMovement(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final db = SqliteService().db;

    // Verificar si el mes existe
    final month =
        await db.monthDao
            .findMonthByMonthAndYear(_selectedDate.month, _selectedDate.year)
            .first;

    // Si el mes no existe, preguntar si desea crearlo
    if (month == null) {
      final shouldCreate =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Crear nuevo mes'),
                  content: Text(
                    'El mes ${_selectedDate.month}/${_selectedDate.year} no existe. ¿Deseas crearlo?',
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    MaterialButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sí'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!shouldCreate) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Operación cancelada')));
        }
        return;
      }

      // Crear el nuevo mes
      final newMonth = Month(_selectedDate.month, _selectedDate.year);
      await db.monthDao.insertMonth(newMonth);
    }

    // Obtener el ID del mes (ya sea el existente o el recién creado)
    final monthId =
        (await db.monthDao
                .findMonthByMonthAndYear(
                  _selectedDate.month,
                  _selectedDate.year,
                )
                .first)
            ?.id;

    if (monthId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear el movimiento')),
        );
      }
      return;
    }

    // Crear el movimiento
    final movement = MovementValue(
      DateTime.now().millisecondsSinceEpoch, // ID único basado en timestamp
      monthId,
      _descriptionController.text,
      amount,
      _isExpense,
      _selectedDate.day,
      null, // Categoría - se implementará después
    );
    await db.movementValueDao.insertMovementValue(movement);

    // Actualizar el servicio de finanzas si está disponible
    if (mounted) {
      try {
        final financeService = Provider.of<FinanceService>(
          context,
          listen: false,
        );
        await financeService.updateSelectedDate(
          _selectedDate.month,
          _selectedDate.year,
        );
      } catch (e) {
        debugPrint('No se pudo actualizar el servicio de finanzas: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimiento guardado con éxito')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isExpense ? 'Nuevo Gasto' : 'Nuevo Ingreso')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  border: OutlineInputBorder(),
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
              const Spacer(),

              // Botón de guardar
              FilledButton(
                onPressed: () => _saveMovement(context),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
