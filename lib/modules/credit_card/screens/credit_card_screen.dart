import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_expense_form.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_history_screen.dart';
import 'package:cashly/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cashly/data/services/device_identity_service.dart';
import 'package:cashly/data/services/nearby_service.dart';
import 'package:cashly/modules/settings.dart/screens/device_pairing_screen.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
  final CreditCardService _service = CreditCardService.getInstance();
  late DateTime _selectedDate;
  String _moneda = '€';

  bool _isSyncing = false;
  final NearbyService _nearbyService = NearbyService();

  bool _isReceiving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
    _loadCurrency();
    NotificationService().requestPermissions();
    _startReceivingIfPaired();
  }

  Future<void> _startReceivingIfPaired() async {
    final trustedPeer = await DeviceIdentityService().getTrustedPeer();
    if (trustedPeer != null && _service.currentMonth != null) {
      setState(() {
        _isReceiving = true;
      });
      await _nearbyService.startReceivingMode(_service.currentMonth!.id!, () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movimientos recibidos y actualizados')),
          );
          _loadData();
        }
      });
    }
  }

  @override
  void dispose() {
    _nearbyService.stopAll();
    super.dispose();
  }

  Future<void> _syncMovements() async {
    final trustedPeer = await DeviceIdentityService().getTrustedPeer();
    
    if (trustedPeer == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dispositivo no vinculado'),
          content: const Text('No hay ningún dispositivo vinculado para sincronizar. Vamos a vincular uno ahora.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DevicePairingScreen()),
                ).then((_) => _startReceivingIfPaired());
              },
              child: const Text('Vincular'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _isReceiving = false;
    });

    await _nearbyService.stopAll();

    try {
      final result = await _nearbyService.sendMovements(
        movements: _service.currentExpenses,
        trustedPeerUuid: trustedPeer['uuid']!,
      );

      if (!mounted) return;

      if (result == SyncResult.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movimientos enviados correctamente')),
        );
      } else if (result == SyncResult.peerNotFound) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Dispositivo no encontrado'),
            content: Text('No se encontró el dispositivo vinculado (${trustedPeer['name']}). Asegúrate de que esté en la pantalla de la tarjeta de crédito con la pantalla encendida.\n\n¿Quieres vincular otro dispositivo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DevicePairingScreen()),
                  ).then((_) => _startReceivingIfPaired());
                },
                child: const Text('Vincular otro'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al sincronizar movimientos'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        // Restart receiving mode after sending
        _startReceivingIfPaired();
      }
    }
  }

  Future<void> _loadCurrency() async {
    final currency = await SharedPreferencesService().getStringValue(SharedPreferencesKeys.currency);
    if (mounted) {
      setState(() {
        _moneda = currency ?? '€';
      });
    }
  }

  Future<void> _loadData() async {
    await _service.loadMonthData(_selectedDate.month, _selectedDate.year);
  }

  void _showLimitDialog() {
    final TextEditingController controller = TextEditingController(
      text: _service.currentMonth?.limitAmount.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Límite mensual'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Límite ($_moneda)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text.replaceAll(',', '.'));
              if (limit != null) {
                _service.setMonthLimit(_selectedDate.month, _selectedDate.year, limit);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjeta de Crédito'),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar movimientos',
              onPressed: _service.currentMonth != null ? _syncMovements : null,
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreditCardHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _service,
        builder: (context, child) {
          return Column(
            children: [
              _buildMonthSelector(),
              if (_service.currentMonth == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No hay límite establecido para este mes'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showLimitDialog,
                          child: const Text('Establecer Límite'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildSummaryCard(),
                const Divider(),
                Expanded(
                  child: _buildExpensesList(),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: _service.currentMonth != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreditCardExpenseForm(
                        month: _selectedDate.month,
                        year: _selectedDate.year,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isReceiving)
            const Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: 'Listo para recibir movimientos',
                child: Icon(Icons.sensors, color: Colors.green, size: 20),
              ),
            ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final remaining = _service.remainingAmount;
    final totalSpent = _service.totalSpent;
    final limit = _service.currentMonth!.limitAmount;
    final isOverLimit = remaining < 0;

    return GestureDetector(
      onTap: _showLimitDialog,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isOverLimit ? Colors.red.withOpacity(0.1) : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOverLimit ? Colors.red : Theme.of(context).colorScheme.primary.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Puedes gastar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '${remaining.toStringAsFixed(2)} $_moneda',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: isOverLimit ? Colors.red : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Límite', style: TextStyle(fontSize: 12)),
                    Text('${limit.toStringAsFixed(2)} $_moneda', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Gastado', style: TextStyle(fontSize: 12)),
                    Text('${totalSpent.toStringAsFixed(2)} $_moneda', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: limit > 0 ? (totalSpent / limit).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: isOverLimit ? Colors.red : Theme.of(context).colorScheme.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    final expenses = _service.currentExpenses;

    if (expenses.isEmpty) {
      return const Center(
        child: Text('No hay gastos este mes'),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: Key(expense.id.toString()),
          background: Container(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showModalBottomSheet<bool>(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Opciones del gasto',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Editar'),
                        onTap: () {
                          Navigator.pop(context, false); // No dismiss
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreditCardExpenseForm(
                                month: _selectedDate.month,
                                year: _selectedDate.year,
                                expenseToEdit: expense,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text('Borrar', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context, true); // Dismiss and delete
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
          onDismissed: (direction) {
            _service.deleteExpense(expense);
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.credit_card),
            ),
            title: Text(expense.description),
            subtitle: Text('${expense.day}/${_selectedDate.month}/${_selectedDate.year}'),
            trailing: Text(
              '-${expense.amount.toStringAsFixed(2)} $_moneda',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
