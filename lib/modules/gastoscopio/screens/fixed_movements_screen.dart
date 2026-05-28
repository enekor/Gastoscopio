import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/debt_definition.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class FixedMovementsScreen extends StatefulWidget {
  const FixedMovementsScreen({super.key});

  @override
  State<FixedMovementsScreen> createState() => _FixedMovementsScreenState();
}

class _FixedMovementsScreenState extends State<FixedMovementsScreen> {
  late String _moneda = '';
  List<FixedMovement> _fixedMovements = [];
  List<DebtDefinition> _monthlyDebtDefinitions = [];
  bool _isOpaqueBottomNav = false;

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

    SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav)
        .then(
          (isOpaque) => setState(() {
            _isOpaqueBottomNav = isOpaque ?? false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                AppLocalizations.of(context)!.fixedMovements,
                style: TextStyle(
                  fontFamily: 'Pacifico',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Info Card
          SliverToBoxAdapter(
            child: Container(
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
                          AppLocalizations.of(context)!.automaticMovements,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.addedAutomaticallyEachMonth,
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
          ),

          SliverToBoxAdapter(
            child: _buildSectionTitle(AppLocalizations.of(context)!.fixedMovements),
          ),
          if (_fixedMovements.isEmpty)
            SliverToBoxAdapter(child: _buildInlineEmpty(AppLocalizations.of(context)!.noFixedMovements))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final movement = _fixedMovements[index];
                  return _buildMovementCard(movement, index);
                }, childCount: _fixedMovements.length),
              ),
            ),
          SliverToBoxAdapter(
            child: _buildSectionTitle('Deudas mensuales'),
          ),
          if (_monthlyDebtDefinitions.isEmpty)
            SliverToBoxAdapter(
              child: _buildInlineEmpty('Aún no tienes deudas mensuales.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final debtDefinition = _monthlyDebtDefinitions[index];
                  return _buildMonthlyDebtDefinitionCard(debtDefinition, index);
                }, childCount: _monthlyDebtDefinitions.length),
              ),
            ),
          

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        icon: Icon(
          Icons.add,
          color: _isOpaqueBottomNav
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          AppLocalizations.of(context)!.add,
          style: TextStyle(
            color: _isOpaqueBottomNav
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _isOpaqueBottomNav
            ? Theme.of(context).colorScheme.primary.withAlpha(200)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: _isOpaqueBottomNav
              ? BorderSide.none
              : BorderSide(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message),
        ),
      ),
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
                AppLocalizations.of(context)!.delete,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          await _showFixedMovementSwipeActions(movement);
          return false;
        },
        onDismissed: (_) {},
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
                final result = await showDialog<List<dynamic>>(
                  context: context,
                  builder: (context) =>
                      _FixedMovementDialog(movement: movement),
                );
                if (result != null) {
                  await SqliteService().database.fixedMovementDao
                      .updateFixedMovement(result[0] as FixedMovement);
                  await SharedPreferencesService().haveToUpload();
            await _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.errorUpdatingMovement(e.toString()),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                LogFileService().appendLog('Error updating movement: $e');
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: movement.isExpense
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              movement.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: movement.isExpense ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
                      AppLocalizations.of(
                        context,
                      )!.dayOfEachMonth(movement.day),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                movement.isExpense
                    ? AppLocalizations.of(context)!.expense
                    : AppLocalizations.of(context)!.income,
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

  Widget _buildMonthlyDebtDefinitionCard(DebtDefinition debtDefinition, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('monthly_debt_${debtDefinition.id ?? index}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDeleteMonthlyDebt(debtDefinition),
        background: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white, size: 28),
        ),
        onDismissed: (_) => _deleteMonthlyDebt(debtDefinition),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _editMonthlyDebt(debtDefinition),
            onLongPress: () => _showMonthlyDebtLongPressActions(debtDefinition),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    debtDefinition.isExpense
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: debtDefinition.isExpense ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debtDefinition.description,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.dayOfEachMonth(debtDefinition.startDay),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${debtDefinition.isExpense ? '-' : '+'}${debtDefinition.amount.toStringAsFixed(2)}$_moneda',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: debtDefinition.isExpense ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
