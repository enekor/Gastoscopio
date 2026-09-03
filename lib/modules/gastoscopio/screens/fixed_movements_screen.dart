import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/debt_definition.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/recurring_form_screen.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_button.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class FixedMovementsScreen extends StatefulWidget {
  /// When embedded in the Gestión tab, renders content only (no Scaffold/AppBar);
  /// the "add" action is shown inline instead of a FloatingActionButton.
  final bool embedded;
  const FixedMovementsScreen({super.key, this.embedded = false});

  @override
  State<FixedMovementsScreen> createState() => _FixedMovementsScreenState();
}

class _FixedMovementsScreenState extends State<FixedMovementsScreen> {
  late String _moneda = '';
  List<FixedMovement> _fixedMovements = [];
  List<DebtDefinition> _monthlyDebtDefinitions = [];

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

    _loadData();
  }

  Future<void> _loadData() async {
    final financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    try {
      final movements = await SqliteService().database.fixedMovementDao
          .findAllFixedMovements();
      final debtDefinitions = await financeService.getMonthlyDebtDefinitions();
      if (mounted) {
        setState(() {
          _fixedMovements = movements;
          _monthlyDebtDefinitions = debtDefinitions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLoadingMovements(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      LogFileService().appendLog('Error loading fixed movements: $e');
    }
  }

  Future<void> _addFixedMovement() async {
    try {
      final result = await showDialog<List<dynamic>>(
        context: context,
        builder: (context) => _FixedMovementDialog(),
      );
      if (result != null) {
        await SqliteService().database.fixedMovementDao.insertFixedMovement(
          result[0],
        );
        await SharedPreferencesService().haveToUpload();
        await _loadData();

        if (result[1] == true) {
          await SqliteService().database.movementValueDao.insertMovementValue(
            MovementValue(
              DateTime.now().millisecondsSinceEpoch,
              FinanceService.getInstance(
                    SqliteService().database.monthDao,
                    SqliteService().database.movementValueDao,
                    SqliteService().database.fixedMovementDao,
                  ).currentMonth?.id ??
                  -1,
              result[0].description,
              result[0].amount,
              result[0].isExpense,
              DateTime.now().day > result[0].day &&
                      DateTime.now().month == DateTime.now().month
                  ? DateTime(
                      DateTime.now().year,
                      DateTime.now().month + 1,
                      0,
                    ).day
                  : result[0].day <=
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month + 1,
                          0,
                        ).day
                  ? result[0].day
                  : DateTime(
                      DateTime.now().year,
                      DateTime.now().month + 1,
                      0,
                    ).day,
              null,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorCreatingMovement(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      LogFileService().appendLog('Error creating fixed movement: $e');
    }
  }

  Future<void> _addMonthlyDebt() async {
    final financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    try {
      final result = await showDialog<DebtDefinition>(
        context: context,
        builder: (context) => const _MonthlyDebtDialog(),
      );
      if (result != null) {
        await financeService.createMonthlyDebtDefinition(
          description: result.description,
          amount: result.amount,
          isExpense: result.isExpense,
          day: result.startDay,
          category: result.category,
        );
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorCreatingMovement(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileService().appendLog('Error creating monthly debt: $e');
    }
  }

  Future<void> _showAddOptions() async {
    final localizations = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.repeat),
                title: Text(localizations.newFixedMovement),
                subtitle: Text(localizations.createRecurringMovements),
                onTap: () {
                  Navigator.pop(context);
                  _addFixedMovement();
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_page_outlined),
                title: Text(AppLocalizations.of(context)!.monthlyDebt),
                subtitle: Text(
                  AppLocalizations.of(context)!.monthlyDebtDescription,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _addMonthlyDebt();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMonthlyDebt(DebtDefinition debtDefinition) async {
    final financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    try {
      final result = await showDialog<DebtDefinition>(
        context: context,
        builder: (context) => _MonthlyDebtDialog(definition: debtDefinition),
      );
      if (result != null) {
        await financeService.updateDebtDefinition(result);
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorUpdatingMovement(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileService().appendLog('Error updating debt definition: $e');
    }
  }

  Future<void> _deleteMonthlyDebt(DebtDefinition debtDefinition) async {
    final financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    try {
      await financeService.deleteDebtDefinition(debtDefinition);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorDeletingMovement(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileService().appendLog('Error deleting debt definition: $e');
    }
  }

  Future<bool> _confirmDeleteFixedMovement(FixedMovement movement) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMovement),
        content: Text(
          AppLocalizations.of(context)!.confirmDeleteMovement(movement.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteFixedMovement(FixedMovement movement) async {
    try {
      await SqliteService().database.fixedMovementDao.deleteFixedMovement(movement);
      await SharedPreferencesService().haveToUpload();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.movementDeleted(movement.description),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorDeletingMovement(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileService().appendLog('Error deleting fixed movement: $e');
    }
  }

  Future<void> _showFixedMovementSwipeActions(FixedMovement movement) async {
    final financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await financeService.convertFixedMovementToMonthlyDebt(
                        movement,
                      );
                      await _loadData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.movementConvertedToMonthlyDebt,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.convertToDebtError(e.toString()),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.request_page_outlined),
                  label: Text(AppLocalizations.of(context)!.convertToMonthlyDebt),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirmed = await _confirmDeleteFixedMovement(movement);
                    if (!confirmed) return;
                    await _deleteFixedMovement(movement);
                  },
                  icon: const Icon(Icons.delete),
                  label: Text(AppLocalizations.of(context)!.delete),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteMonthlyDebt(DebtDefinition debtDefinition) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMovement),
        content: Text(
          AppLocalizations.of(context)!.confirmDeleteMovement(
            debtDefinition.description,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<int?> _askTargetDayForFixedMovement(int initialDay) async {
    final controller = TextEditingController(text: initialDay.toString());
    final formKey = GlobalKey<FormState>();
    final selectedDay = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.convertToMonthlyMovement),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Día del mes',
              hintText: '1-31',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
      final day = int.tryParse(value ?? '');
              if (day == null || day < 1 || day > 31) {
                return AppLocalizations.of(context)!.invalidDayRange;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, int.parse(controller.text));
            },
            child: Text(AppLocalizations.of(context)!.continueAction),
          ),
        ],
      ),
    );
    controller.dispose();
    return selectedDay;
  }

  Future<void> _showMonthlyDebtLongPressActions(DebtDefinition debtDefinition) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(
                AppLocalizations.of(context)!.convertToMonthlyMovement,
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.convertToMonthlyMovementSubtitle,
              ),
              onTap: () => Navigator.pop(context, 'to_fixed'),
            ),
          ],
        ),
      ),
    );
    if (action != 'to_fixed') return;

    final day = await _askTargetDayForFixedMovement(debtDefinition.startDay);
    if (day == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmConversion),
        content: Text(
          AppLocalizations.of(
            context,
          )!.convertDebtToMovementConfirm(debtDefinition.description, day),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final financeService = FinanceService.getInstance(
      SqliteService().database.monthDao,
      SqliteService().database.movementValueDao,
      SqliteService().database.fixedMovementDao,
    );
    try {
      await financeService.convertMonthlyDebtToFixedMovement(debtDefinition, day);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.monthlyDebtConvertedToMovement,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.convertToDebtError('$e')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      LogFileService().appendLog('Error converting monthly debt to fixed movement: $e');
    }
  }

  /// Sum of the estimated monthly recurring expense amounts (fixed movements +
  /// monthly debt definitions). Incomes are subtracted so the figure reflects
  /// the net estimated monthly outflow.
  double get _estimatedMonthlyTotal {
    double total = 0;
    for (final m in _fixedMovements) {
      total += m.isExpense ? m.amount : -m.amount;
    }
    for (final d in _monthlyDebtDefinitions) {
      total += d.isExpense ? d.amount : -d.amount;
    }
    return total;
  }

  Future<void> _openRecurringForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RecurringFormScreen()),
    );
    if (created == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasItems =
        _fixedMovements.isNotEmpty || _monthlyDebtDefinitions.isNotEmpty;

    final listView = ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, widget.embedded ? 120 : 96),
      children: [
        if (widget.embedded)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openRecurringForm,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context)!.newMovementTitle),
            ),
          ),
        _buildTotalCard(context),
        const SizedBox(height: 24),
        SectionHeader(title: AppLocalizations.of(context)!.upcomingCharges),
        const SizedBox(height: 8),
        if (!hasItems)
          _buildInlineEmpty(
            AppLocalizations.of(context)!.noFixedMovements,
          )
        else ...[
          for (int i = 0; i < _fixedMovements.length; i++) ...[
            _buildMovementCard(_fixedMovements[i], i),
            const SizedBox(height: 12),
          ],
          for (int i = 0; i < _monthlyDebtDefinitions.length; i++) ...[
            _buildMonthlyDebtDefinitionCard(_monthlyDebtDefinitions[i], i),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );

    if (widget.embedded) {
      return listView;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.fixedMovements,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(top: false, child: listView),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRecurringForm,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.estimatedMonthlyTotal.toUpperCase(),
            style: TextStyle(
              color: glass.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          AmountText(
            amount: _estimatedMonthlyTotal,
            currency: _moneda.isEmpty ? '€' : _moneda,
            fontSize: 44,
          ),
        ],
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
              AppLocalizations.of(context)!.noFixedMovements,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.createRecurringMovements,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.createFirstMovement),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInlineEmpty(String message) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Text(
        message,
        style: TextStyle(color: glass.mutedText),
      ),
    );
  }

  /// Opens the edit dialog for a fixed movement (preserves the previous
  /// on-tap/edit behaviour of the card).
  Future<void> _editFixedMovement(FixedMovement movement) async {
    try {
      final result = await showDialog<List<dynamic>>(
        context: context,
        builder: (context) => _FixedMovementDialog(movement: movement),
      );
      if (result != null) {
        await SqliteService().database.fixedMovementDao.updateFixedMovement(
          result[0] as FixedMovement,
        );
        await SharedPreferencesService().haveToUpload();
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorUpdatingMovement(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      LogFileService().appendLog('Error updating movement: $e');
    }
  }

  /// Shows a read-only "Detalles" sheet for a recurring item.
  Future<void> _showDetails({
    required String title,
    required String? category,
    required int day,
    required double amount,
    required bool isExpense,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerHigh,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              AmountText(
                amount: amount,
                currency: _moneda.isEmpty ? '€' : _moneda,
                isExpense: isExpense,
                signed: true,
                fontSize: 32,
              ),
              const SizedBox(height: 16),
              _detailRow(
                Icons.calendar_today,
                AppLocalizations.of(context)!.dayOfEachMonth(day),
              ),
              if (category != null && category.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.tag, category),
              ],
              const SizedBox(height: 8),
              _detailRow(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                isExpense
                    ? AppLocalizations.of(context)!.expense
                    : AppLocalizations.of(context)!.income,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.monthly,
                style: TextStyle(color: glass.mutedText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Row(
      children: [
        Icon(icon, size: 16, color: glass.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: glass.mutedText, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, {required bool positive}) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final color = positive ? glass.incomeColor : glass.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMovementCard(FixedMovement movement, int index) {
    return Dismissible(
      key: Key('fixed_movement_${movement.id ?? index}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(
            Theme.of(context).extension<AppGlass>()!.cardRadius,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        await _showFixedMovementSwipeActions(movement);
        return false;
      },
      onDismissed: (_) {},
      child: _buildRecurringCard(
        title: movement.description,
        category: movement.category,
        day: movement.day,
        amount: movement.amount,
        isExpense: movement.isExpense,
        statusLabel: AppLocalizations.of(context)!.activeStatus,
        statusPositive: true,
        onTap: () => _editFixedMovement(movement),
        onDetails: () => _showDetails(
          title: movement.description,
          category: movement.category,
          day: movement.day,
          amount: movement.amount,
          isExpense: movement.isExpense,
        ),
        onEdit: () => _editFixedMovement(movement),
      ),
    );
  }

  Widget _buildMonthlyDebtDefinitionCard(
    DebtDefinition debtDefinition,
    int index,
  ) {
    return Dismissible(
      key: Key('monthly_debt_${debtDefinition.id ?? index}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteMonthlyDebt(debtDefinition),
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(
            Theme.of(context).extension<AppGlass>()!.cardRadius,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteMonthlyDebt(debtDefinition),
      child: _buildRecurringCard(
        title: debtDefinition.description,
        category: debtDefinition.category,
        day: debtDefinition.startDay,
        amount: debtDefinition.amount,
        isExpense: debtDefinition.isExpense,
        subtitleOverride: AppLocalizations.of(context)!.recurringDebt,
        statusLabel: AppLocalizations.of(context)!.pendingStatus,
        statusPositive: false,
        onTap: () => _editMonthlyDebt(debtDefinition),
        onLongPress: () => _showMonthlyDebtLongPressActions(debtDefinition),
        onDetails: () => _showDetails(
          title: debtDefinition.description,
          category: debtDefinition.category,
          day: debtDefinition.startDay,
          amount: debtDefinition.amount,
          isExpense: debtDefinition.isExpense,
        ),
        onEdit: () => _editMonthlyDebt(debtDefinition),
      ),
    );
  }

  Widget _buildRecurringCard({
    required String title,
    required String? category,
    required int day,
    required double amount,
    required bool isExpense,
    required String statusLabel,
    required bool statusPositive,
    required VoidCallback onTap,
    required VoidCallback onDetails,
    required VoidCallback onEdit,
    String? subtitleOverride,
    VoidCallback? onLongPress,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final subtitle =
        subtitleOverride ??
        AppLocalizations.of(context)!.dayOfEachMonth(day);
    return GlassCard(
      onTap: onTap,
      child: GestureDetector(
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 20,
                    color: isExpense ? glass.expenseColor : glass.incomeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: glass.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmountText(
                      amount: amount,
                      currency: _moneda.isEmpty ? '€' : _moneda,
                      isExpense: isExpense,
                      signed: true,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 4),
                    _statusChip(statusLabel, positive: statusPositive),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: AppLocalizations.of(context)!.detailsLabel,
                    onPressed: onDetails,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: AppLocalizations.of(context)!.edit,
                    onPressed: onEdit,
                  ),
                ),
              ],
            ),
          ],
        ),
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

class _MonthlyDebtDialog extends StatefulWidget {
  final DebtDefinition? definition;

  const _MonthlyDebtDialog({this.definition});

  @override
  State<_MonthlyDebtDialog> createState() => _MonthlyDebtDialogState();
}

class _MonthlyDebtDialogState extends State<_MonthlyDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _dayController;
  late bool _isExpense;
  String? _category;
  String _moneda = '€';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.definition?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.definition?.amount.toStringAsFixed(2) ?? '',
    );
    _dayController = TextEditingController(
      text: widget.definition?.startDay.toString() ?? '',
    );
    _isExpense = widget.definition?.isExpense ?? true;
    _category = widget.definition?.category;

    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then((currency) {
          if (!mounted) return;
          setState(() {
            _moneda = currency ?? '€';
          });
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
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.definition == null
            ? localizations.createMonthlyDebt
            : localizations.editMonthlyDebt,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.description,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true
                    ? localizations.descriptionRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: localizations.amount,
                  suffixText: _moneda,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty == true) return localizations.amountRequired;
                  final amount = double.tryParse(value!.replaceAll(',', '.'));
                  if (amount == null) return localizations.enterValidNumber;
                  if (amount <= 0) return localizations.amountMustBeGreaterThanZero;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dayController,
                decoration: InputDecoration(
                  labelText: localizations.dayOfMonth,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return localizations.dayRequired;
                  final day = int.tryParse(value!);
                  if (day == null || day < 1 || day > 31) {
                    return localizations.dayMustBeBetween1And31;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(localizations.iOwe),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(localizations.owedToMe),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_isExpense},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isExpense = selection.first;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            final amount = double.parse(_amountController.text.replaceAll(',', '.'));
            final day = int.parse(_dayController.text);
            Navigator.of(context).pop(
              DebtDefinition(
                widget.definition?.id,
                _descriptionController.text.trim(),
                amount,
                _isExpense,
                _category,
                debtRecurrenceMonthly,
                day,
                widget.definition?.startMonth ?? DateTime.now().month,
                widget.definition?.startYear ?? DateTime.now().year,
                true,
              ),
            );
          },
          child: Text(widget.definition == null ? localizations.create : localizations.save),
        ),
      ],
    );
  }
}

class _FixedMovementDialogState extends State<_FixedMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _dayController;
  late bool _isExpense;
  late String? _category;
  String _moneda = '€';
  bool _saveInCurrentMonth = false;

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
                ? AppLocalizations.of(context)!.newFixedMovement
                : AppLocalizations.of(context)!.editMovement,
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
                Text(
                  AppLocalizations.of(context)!.description,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    )!.exampleSalaryRentNetflix,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  validator: (value) => value?.isEmpty == true
                      ? AppLocalizations.of(context)!.descriptionRequired
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.quantity,
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
                      return AppLocalizations.of(context)!.amountRequired;
                    if (double.tryParse(value!) == null)
                      return AppLocalizations.of(context)!.enterValidNumber;
                    if (double.parse(value) <= 0)
                      return AppLocalizations.of(
                        context,
                      )!.amountMustBeGreaterThanZero;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.dayOfMonth,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dayController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.from1To31,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true)
                      return AppLocalizations.of(context)!.dayRequired;
                    final day = int.tryParse(value!);
                    if (day == null)
                      return AppLocalizations.of(context)!.enterValidNumber;
                    if (day < 1 || day > 31)
                      return AppLocalizations.of(
                        context,
                      )!.dayMustBeBetween1And31;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.movementType,
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
                            color: _isExpense
                                ? Colors.red
                                : Colors.grey.withOpacity(0.3),
                            width: _isExpense ? 2 : 1,
                          ),
                          color: _isExpense
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
                                  Icons.arrow_downward,
                                  color: _isExpense ? Colors.red : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.expense,
                                  style: TextStyle(
                                    color: _isExpense
                                        ? Colors.red
                                        : Colors.grey,
                                    fontWeight: _isExpense
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
                            color: !_isExpense
                                ? Colors.green
                                : Colors.grey.withOpacity(0.3),
                            width: !_isExpense ? 2 : 1,
                          ),
                          color: !_isExpense
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
                                  Icons.arrow_upward,
                                  color: !_isExpense
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.income,
                                  style: TextStyle(
                                    color: !_isExpense
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: !_isExpense
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
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.saveInCurrentMonth,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: _saveInCurrentMonth,
                        onChanged: (value) {
                          setState(() {
                            _saveInCurrentMonth = value;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              try {
                final amount = double.parse(_amountController.text);
                final day = int.parse(_dayController.text);

                Navigator.of(context).pop([
                  FixedMovement(
                    widget.movement?.id,
                    _descriptionController.text.trim(),
                    amount,
                    _isExpense,
                    day,
                    _category,
                  ),
                  _saveInCurrentMonth,
                ]);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.errorInData(e.toString()),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                LogFileService().appendLog('Error in dialog data: $e');
              }
            }
          },
          child: Text(
            widget.movement == null
                ? AppLocalizations.of(context)!.create
                : AppLocalizations.of(context)!.save,
          ),
        ),
      ],
    );
  }
}
