import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_expense_form.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_history_screen.dart';
import 'package:cashly/data/services/notification_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/app_list_row.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
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

  // Billing config (loaded from prefs) used to compute next payment / cycle end.
  String _billingCycle = 'monthly';
  int _billingDay = 1;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
    _loadCurrency();
    _loadBillingConfig();
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

  Future<void> _loadBillingConfig() async {
    final prefs = SharedPreferencesService();
    final cycle = await prefs.getStringValue(SharedPreferencesKeys.creditCardBillingCycle) ?? 'monthly';
    final day = (await prefs.getDoubleValue(SharedPreferencesKeys.creditCardBillingDay))?.toInt() ?? 1;
    if (mounted) {
      setState(() {
        _billingCycle = cycle;
        _billingDay = day;
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

  void _showSettingsDialog() async {
    final prefs = SharedPreferencesService();
    final currentCycle = await prefs.getStringValue(SharedPreferencesKeys.creditCardBillingCycle) ?? 'monthly';
    final currentBillingDay = (await prefs.getDoubleValue(SharedPreferencesKeys.creditCardBillingDay))?.toInt() ?? 1;
    final currentDefaultLimit = await _service.getDefaultLimit();

    if (!mounted) return;

    String selectedCycle = currentCycle;
    int selectedBillingDay = currentBillingDay;
    final TextEditingController limitController = TextEditingController(text: currentDefaultLimit.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Configuración de Tarjeta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Límite por defecto ($_moneda)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Ciclo de facturación', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Mensual'),
                  value: 'monthly',
                  groupValue: selectedCycle,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCycle = value!;
                      if (selectedBillingDay > 31) selectedBillingDay = 1;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Semanal'),
                  value: 'weekly',
                  groupValue: selectedCycle,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCycle = value!;
                      if (selectedBillingDay > 7) selectedBillingDay = 1;
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (selectedCycle == 'monthly')
                  DropdownButtonFormField<int>(
                    value: selectedBillingDay > 31 ? 1 : selectedBillingDay,
                    decoration: const InputDecoration(labelText: 'Día de cobro (del mes)'),
                    items: List.generate(31, (index) => index + 1)
                        .map((day) => DropdownMenuItem(value: day, child: Text(day.toString())))
                        .toList(),
                    onChanged: (value) => selectedBillingDay = value!,
                  )
                else
                  DropdownButtonFormField<int>(
                    value: selectedBillingDay > 7 ? 1 : selectedBillingDay,
                    decoration: const InputDecoration(labelText: 'Día de cobro (de la semana)'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lunes')),
                      DropdownMenuItem(value: 2, child: Text('Martes')),
                      DropdownMenuItem(value: 3, child: Text('Miércoles')),
                      DropdownMenuItem(value: 4, child: Text('Jueves')),
                      DropdownMenuItem(value: 5, child: Text('Viernes')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 7, child: Text('Domingo')),
                    ],
                    onChanged: (value) => selectedBillingDay = value!,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final limit = double.tryParse(limitController.text.replaceAll(',', '.'));
                if (limit != null) {
                  await prefs.setDoubleValue(SharedPreferencesKeys.creditCardDefaultLimit, limit);
                  await prefs.setStringValue(SharedPreferencesKeys.creditCardBillingCycle, selectedCycle);
                  await prefs.setDoubleValue(SharedPreferencesKeys.creditCardBillingDay, selectedBillingDay.toDouble());

                  if (mounted) Navigator.pop(context);
                  _loadBillingConfig();
                  _loadData();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: _service,
            builder: (context, child) {
              if (_service.currentMonth == null) {
                return Column(
                  children: [
                    _buildMonthSelector(),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No hay límite establecido para este mes',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: scheme.onSurface),
                              ),
                              const SizedBox(height: 16),
                              PrimaryPillButton(
                                label: 'Establecer Límite',
                                expand: false,
                                onPressed: _showLimitDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 12),
                  _buildCreditCardVisual(),
                  const SizedBox(height: 16),
                  _buildBalanceCard(),
                  const SizedBox(height: 16),
                  _buildBillingRow(),
                  const SizedBox(height: 16),
                  _buildInfoNote(),
                  const SizedBox(height: 20),
                  _buildExpensesSection(),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _service.currentMonth != null
          ? FloatingActionButton(
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
            )
          : null,
    );
  }

  Widget _buildMonthSelector() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isReceiving)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Listo para recibir movimientos',
              child: Icon(Icons.sensors, color: Colors.green, size: 20),
            ),
          ),
        Text(
          DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardVisual() {
    // Decorative premium card: dark navy -> emerald gradient.
    const cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0F172A), Color(0xFF134E4A), Color(0xFF10B981)],
      stops: [0.0, 0.6, 1.0],
    );
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(gradient: cardGradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.premiumCard,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (_isSyncing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  else
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.contactless, color: Colors.white70),
                      tooltip: 'Sincronizar movimientos',
                      onPressed:
                          _service.currentMonth != null ? _syncMovements : null,
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                '****  ****  ****  4921',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'JUAN PEREZ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '12/28',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final totalSpent = _service.totalSpent;
    final limit = _service.currentMonth!.limitAmount;
    final remaining = _service.remainingAmount;
    final isOverLimit = remaining < 0;
    final progress = limit > 0 ? (totalSpent / limit).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      onTap: _showLimitDialog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.usedBalance,
                style: TextStyle(color: glass.mutedText, fontSize: 15),
              ),
              AmountText(
                amount: totalSpent,
                currency: _moneda,
                fontSize: 28,
                color: isOverLimit ? glass.expenseColor : scheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: scheme.surfaceContainerHigh,
              color: isOverLimit ? glass.expenseColor : scheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.creditLimit,
                style: TextStyle(color: glass.mutedText, fontSize: 14),
              ),
              Text(
                '${limit.toStringAsFixed(2)} $_moneda',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Computes the next payment date and the current cycle closing date from the
  /// stored billing config (reusing prefs creditCardBillingDay/Cycle).
  ({DateTime nextPayment, DateTime cycleClose, int daysLeft}) _billingInfo() {
    final now = DateTime.now();
    DateTime cycleClose;
    if (_billingCycle == 'weekly') {
      int daysToAdd = (_billingDay - now.weekday) % 7;
      if (daysToAdd <= 0) daysToAdd += 7;
      cycleClose = DateTime(now.year, now.month, now.day).add(Duration(days: daysToAdd));
    } else {
      final day = _billingDay.clamp(1, 28);
      if (now.day < day) {
        cycleClose = DateTime(now.year, now.month, day);
      } else {
        cycleClose = DateTime(now.year, now.month + 1, day);
      }
    }
    final daysLeft = cycleClose.difference(DateTime(now.year, now.month, now.day)).inDays;
    // Payment is typically due after the cycle closes.
    final nextPayment = cycleClose;
    return (nextPayment: nextPayment, cycleClose: cycleClose, daysLeft: daysLeft);
  }

  Widget _buildBillingRow() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final info = _billingInfo();
    final remaining = _service.remainingAmount;
    // Minimum payment heuristic reused from existing values (used balance).
    final minimum = _service.totalSpent > 0
        ? (_service.totalSpent * 0.05).clamp(0.0, _service.totalSpent)
        : 0.0;

    Widget miniCard({
      required IconData icon,
      required String label,
      required String value,
      String? footer,
      Color? footerColor,
    }) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: glass.mutedText),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(color: glass.mutedText, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 4),
              Text(
                footer,
                style: TextStyle(
                  color: footerColor ?? glass.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: miniCard(
            icon: Icons.event,
            label: AppLocalizations.of(context)!.nextPayment,
            value: DateFormat('dd MMM').format(info.nextPayment),
            footer:
                '${AppLocalizations.of(context)!.minimumLabel}: ${minimum.toStringAsFixed(2)} $_moneda',
            footerColor: glass.expenseColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: miniCard(
            icon: Icons.receipt_long,
            label: AppLocalizations.of(context)!.billingClose,
            value: DateFormat('dd MMM').format(info.cycleClose),
            footer: info.daysLeft == 1
                ? 'Falta 1 día'
                : 'Faltan ${info.daysLeft} días',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: glass.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estos valores representan exclusivamente el estado de su tarjeta de crédito y no afectan ni se reflejan en el saldo principal de sus cuentas bancarias.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final expenses = _service.currentExpenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.expenses,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No hay gastos este mes',
                style: TextStyle(color: glass.mutedText),
              ),
            ),
          )
        else
          ...expenses.map((expense) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: Key(expense.id.toString()),
                background: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(glass.cardRadius),
                  ),
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
                child: AppListRow(
                  leadingIcon: Icons.credit_card,
                  title: expense.description,
                  subtitle: '${expense.day}/${_selectedDate.month}/${_selectedDate.year}',
                  trailing: AmountText(
                    amount: expense.amount,
                    currency: _moneda,
                    isExpense: true,
                    signed: true,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
