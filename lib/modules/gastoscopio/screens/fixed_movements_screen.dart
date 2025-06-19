import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    try {
      final movements =
          await SqliteService().database.fixedMovementDao
              .findAllFixedMovements();
      if (mounted) {
        setState(() {
          _fixedMovements = movements;
        });
      }
    } catch (e) {
      // En caso de error, mantener la lista actual y mostrar mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar movimientos: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addFixedMovement() async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear movimiento: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Movimientos Fijos',
          style: GoogleFonts.pacifico(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Movimientos Automáticos',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se añaden automáticamente cada mes nuevo.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child:
                _fixedMovements.isEmpty
                    ? _buildEmptyState()
                    : _buildMovementsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFixedMovement,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
        label: Text(
          'Añadir',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin movimientos fijos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crea movimientos que se repitan automáticamente cada mes, como salarios, alquileres o suscripciones.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _addFixedMovement,
              icon: const Icon(Icons.add),
              label: const Text('Crear primer movimiento.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _fixedMovements.length,
      itemBuilder: (context, index) {
        final movement = _fixedMovements[index];
        return _buildMovementCard(movement, index);
      },
    );
  }

  Widget _buildMovementCard(FixedMovement movement, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('fixed_movement_${movement.id ?? index}'),
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                'Eliminar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          try {
            await SqliteService().database.fixedMovementDao.deleteFixedMovement(
              movement,
            );
            setState(() {
              _fixedMovements.removeAt(index);
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Movimiento "${movement.description}" eliminado.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            // Si falla la eliminación, recargar la lista para restaurar el estado
            await _loadFixedMovements();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al eliminar movimiento: $e'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              try {
                final result = await showDialog<FixedMovement>(
                  context: context,
                  builder:
                      (context) => _FixedMovementDialog(movement: movement),
                );

                if (result != null) {
                  await SqliteService().database.fixedMovementDao
                      .updateFixedMovement(result);
                  await _loadFixedMovements();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar movimiento: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: _buildMovementContent(movement),
          ),
        ),
      ),
    );
  }

  Widget _buildMovementContent(FixedMovement movement) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  movement.isExpense
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              movement.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: movement.isExpense ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (movement.category != null &&
                    movement.category!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.tag, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        movement.category!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Día ${movement.day} de cada mes',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${movement.isExpense ? '-' : '+'}${movement.amount.toStringAsFixed(2)}$_moneda',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: movement.isExpense ? Colors.red : Colors.green,
                ),
              ),
              Text(
                movement.isExpense ? 'Gasto' : 'Ingreso',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: movement.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
  String _moneda = '€';

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

    // Load currency
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then((currency) {
          if (mounted) {
            setState(() {
              _moneda = currency ?? '€';
            });
          }
        });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.repeat,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.movement == null
                ? 'Nuevo Movimiento Fijo'
                : 'Editar Movimiento',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Field
                Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Salario, Alquiler, Netflix...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  validator:
                      (value) =>
                          value?.isEmpty == true
                              ? 'La descripción es obligatoria'
                              : null,
                ),

                const SizedBox(height: 20),

                // Amount Field
                Text(
                  'Cantidad',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.euro),
                    suffixText: _moneda,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value?.isEmpty == true)
                      return 'La cantidad es obligatoria.';
                    if (double.tryParse(value!) == null)
                      return 'Introduce un número válido.';
                    if (double.parse(value) <= 0)
                      return 'La cantidad debe ser mayor que 0.';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Day Field
                Text(
                  'Día del mes',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dayController,
                  decoration: InputDecoration(
                    hintText: 'Del 1 al 31',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'El día es obligatorio';
                    final day = int.tryParse(value!);
                    if (day == null) return 'Introduce un número válido';
                    if (day < 1 || day > 31)
                      return 'El día debe estar entre 1 y 31.';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Type Selection
                Text(
                  'Tipo de movimiento',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _isExpense
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.3),
                            width: _isExpense ? 2 : 1,
                          ),
                          color:
                              _isExpense
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.transparent,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _isExpense = true;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  color: _isExpense ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gasto',
                                  style: TextStyle(
                                    color:
                                        _isExpense ? Colors.red : Colors.grey,
                                    fontWeight:
                                        _isExpense
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                !_isExpense
                                    ? Colors.green
                                    : Colors.grey.withOpacity(0.3),
                            width: !_isExpense ? 2 : 1,
                          ),
                          color:
                              !_isExpense
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.transparent,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              _isExpense = false;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color:
                                      !_isExpense ? Colors.green : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ingreso',
                                  style: TextStyle(
                                    color:
                                        !_isExpense
                                            ? Colors.green
                                            : Colors.grey,
                                    fontWeight:
                                        !_isExpense
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              try {
                final amount = double.parse(_amountController.text);
                final day = int.parse(_dayController.text);

                Navigator.of(context).pop(
                  FixedMovement(
                    widget.movement?.id,
                    _descriptionController.text.trim(),
                    amount,
                    _isExpense,
                    day,
                    _category,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error en los datos: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Text(widget.movement == null ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
