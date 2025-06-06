import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:flutter/material.dart';

class FixedMovementsScreen extends StatefulWidget {
  const FixedMovementsScreen({super.key});

  @override
  State<FixedMovementsScreen> createState() => _FixedMovementsScreenState();
}

class _FixedMovementsScreenState extends State<FixedMovementsScreen> {
  late String _moneda = 'loading...';
  List<FixedMovement> _fixedMovements = [];

  @override
  void initState() {
    super.initState();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
    _loadFixedMovements();
  }

  Future<void> _loadFixedMovements() async {
    final movements =
        await SqliteService().database.fixedMovementDao.findAllFixedMovements();
    setState(() {
      _fixedMovements = movements;
    });
  }

  Future<void> _addFixedMovement() async {
    final result = await showDialog<FixedMovement>(
      context: context,
      builder: (context) => _FixedMovementDialog(),
    );

    if (result != null) {
      await SqliteService().database.fixedMovementDao.insertFixedMovement(
        result,
      );
      await _loadFixedMovements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos Fijos')),
      body:
          _fixedMovements.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.repeat, size: 48),
                    const SizedBox(height: 16),
                    const Text('No hay movimientos fijos'),
                    const SizedBox(height: 8),
                    const Text(
                      'Los movimientos fijos se añadirán automáticamente cada mes',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _fixedMovements.length,
                itemBuilder: (context, index) {
                  final movement = _fixedMovements[index];
                  return Dismissible(
                    key: Key(movement.id.toString()),
                    background: Container(
                      color: Theme.of(context).colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      await SqliteService().database.fixedMovementDao
                          .deleteFixedMovement(movement);
                      setState(() {
                        _fixedMovements.removeAt(index);
                      });
                    },
                    child: ListTile(
                      title: Text(movement.description),
                      subtitle: Text('Día ${movement.day}'),
                      trailing: Text(
                        '${movement.isExpense ? '-' : ''}${movement.amount.toStringAsFixed(2)}$_moneda',
                        style: TextStyle(
                          color:
                              movement.isExpense
                                  ? Theme.of(context).colorScheme.error
                                  : Colors.green,
                        ),
                      ),
                      onTap: () async {
                        final result = await showDialog<FixedMovement>(
                          context: context,
                          builder:
                              (context) =>
                                  _FixedMovementDialog(movement: movement),
                        );

                        if (result != null) {
                          await SqliteService().database.fixedMovementDao
                              .updateFixedMovement(result);
                          await _loadFixedMovements();
                        }
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFixedMovement,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FixedMovementDialog extends StatefulWidget {
  final FixedMovement? movement;

  const _FixedMovementDialog({this.movement});

  @override
  State<_FixedMovementDialog> createState() => _FixedMovementDialogState();
}

class _FixedMovementDialogState extends State<_FixedMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _dayController;
  late bool _isExpense;
  late String? _category;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.movement?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.movement?.amount.toStringAsFixed(2) ?? '',
    );
    _dayController = TextEditingController(
      text: widget.movement?.day.toString() ?? '',
    );
    _isExpense = widget.movement?.isExpense ?? true;
    _category = widget.movement?.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.movement == null
            ? 'Nuevo Movimiento Fijo'
            : 'Editar Movimiento Fijo',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator:
                    (value) =>
                        value?.isEmpty == true ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Campo requerido';
                  if (double.tryParse(value!) == null) return 'Valor inválido';
                  return null;
                },
              ),
              TextFormField(
                controller: _dayController,
                decoration: const InputDecoration(labelText: 'Día del mes'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Campo requerido';
                  final day = int.tryParse(value!);
                  if (day == null) return 'Valor inválido';
                  if (day < 1 || day > 31) return 'Día inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('Gasto'),
                    selected: _isExpense,
                    onSelected: (selected) {
                      setState(() {
                        _isExpense = selected;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Ingreso'),
                    selected: !_isExpense,
                    onSelected: (selected) {
                      setState(() {
                        _isExpense = !selected;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.of(context).pop(
                FixedMovement(
                  widget.movement?.id,
                  _descriptionController.text,
                  double.parse(_amountController.text),
                  _isExpense,
                  int.parse(_dayController.text),
                  _category,
                ),
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
