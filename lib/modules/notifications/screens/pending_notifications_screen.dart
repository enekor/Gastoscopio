import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/groq_serice.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/notification_capture_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/notifications/widgets/pending_movement_card.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PendingNotificationsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PendingNotificationsScreen({super.key, required this.onComplete});

  @override
  State<PendingNotificationsScreen> createState() =>
      _PendingNotificationsScreenState();
}

class _PendingNotificationsScreenState
    extends State<PendingNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<EditablePendingMovement> _movements = [];
  bool _isLoading = true;
  bool _isSaving = false;
  int _savingCurrent = 0;
  int _savingTotal = 0;
  bool _isAiProcessing = false;
  int _aiProcessingCurrent = 0;
  int _aiProcessingTotal = 0;
  final Map<String, String> _resolvedAppNames = {};

  @override
  void initState() {
    super.initState();
    _loadPendingMovements();
  }

  @override
  void dispose() {
    for (final m in _movements) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPendingMovements() async {
    try {
      final db = SqliteService().db;
      final pending = await db.pendingNotificationMovementDao.findAll();

      setState(() {
        _movements = pending
            .map(
              (p) => EditablePendingMovement(
                id: p.id,
                originalText: p.notificationText,
                appName: p.appName,
                timestamp: p.timestamp,
                descriptionController: TextEditingController(
                  text: p.notificationText,
                ),
                amountController: TextEditingController(
                  text: p.extractedAmount.toStringAsFixed(2),
                ),
              ),
            )
            .toList();
        _isLoading = false;
      });

      // Resolve app names and run AI parsing in parallel
      if (_movements.isNotEmpty && mounted) {
        _resolveAppNames();
        _runAiParsing(pending.map((p) => p.extractedAmount).toList());
      }
    } catch (e) {
      LogFileService().appendLog('Error loading pending notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveAppNames() async {
    final uniquePackages = _movements.map((m) => m.appName).toSet();
    for (final pkg in uniquePackages) {
      try {
        final name = await NotificationCaptureService().getAppName(pkg);
        if (mounted) {
          setState(() => _resolvedAppNames[pkg] = name);
        }
      } catch (_) {}
    }
  }

  Future<void> _disallowApp(int index) async {
    final movement = _movements[index];
    final packageName = movement.appName;
    final appName = _resolvedAppNames[packageName] ?? packageName;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_off_outlined),
        title: Text(AppLocalizations.of(context)!.disallowApp),
        content: Text(AppLocalizations.of(context)!.disallowAppConfirmation(appName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await NotificationCaptureService().disallowApp(packageName);

    // Remove all movements from this app
    setState(() {
      _movements.where((m) => m.appName == packageName).forEach((m) => m.dispose());
      _movements.removeWhere((m) => m.appName == packageName);
    });

    if (_movements.isEmpty) {
      _dismissAll();
    }
  }

  Future<void> _runAiParsing(List<double> fallbackAmounts) async {
    if (!mounted) return;
    setState(() {
      _isAiProcessing = true;
      _aiProcessingTotal = _movements.length;
      _aiProcessingCurrent = 0;
    });

    for (int i = 0; i < _movements.length; i++) {
      if (!mounted) return;
      final m = _movements[i];
      setState(() => _aiProcessingCurrent = i + 1);

      try {
        final result = await GroqService().parseNotificationTransaction(
          m.originalText,
          m.appName,
          fallbackAmounts[i],
          context,
        );
        if (!mounted) return;
        if (result != null) {
          setState(() {
            final title = result['title'] as String;
            final amount = result['amount'] as double;
            final isExpense = result['isExpense'] as bool;
            m.descriptionController.text = title;
            m.amountController.text = amount.toStringAsFixed(2);
            m.isExpense = isExpense;
          });
        }
      } catch (e) {
        LogFileService().appendLog(
          'AI parsing failed for notification ${m.id}: $e',
        );
      }
    }

    if (mounted) {
      setState(() => _isAiProcessing = false);
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _savingTotal = _movements.length;
      _savingCurrent = 0;
    });

    final db = SqliteService().db;
    final financeService = FinanceService.getInstance(
      db.monthDao,
      db.movementValueDao,
      db.fixedMovementDao,
    );

    try {
      for (int i = 0; i < _movements.length; i++) {
        setState(() => _savingCurrent = i + 1);

        final m = _movements[i];
        final amount = double.parse(
          m.amountController.text.replaceAll(',', '.'),
        );
        final date = DateTime.tryParse(m.timestamp) ?? DateTime.now();

        // Get or create month
        final monthId = await financeService.findMonthByMonthAndYear(
          date.month,
          date.year,
        );

        // AI category generation
        String? category;
        try {
          category = await GroqService()
              .generateCategory(
                m.descriptionController.text,
                m.isExpense,
                context,
              )
              .timeout(const Duration(seconds: 10), onTimeout: () => '');
          if (category.isEmpty) category = '';
        } catch (e) {
          category = '';
          LogFileService().appendLog(
            'Error generating category for notification movement: $e',
          );
        }

        // Create and insert movement
        final movement = MovementValue(
          DateTime.now().millisecondsSinceEpoch,
          monthId,
          m.descriptionController.text,
          amount,
          m.isExpense,
          date.day,
          category?.trim(),
        );
        await db.movementValueDao.insertMovementValue(movement);
        await SharedPreferencesService().haveToUpload();
      }

      // Clear pending table
      await db.pendingNotificationMovementDao.deleteAll();

      // Refresh finance data
      final now = DateTime.now();
      await financeService.updateSelectedDate(now.month, now.year);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pendingNotificationsSaved,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      widget.onComplete();
    } catch (e) {
      LogFileService().appendLog('Error saving notification movements: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.generalError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _dismissAll() async {
    final db = SqliteService().db;
    await db.pendingNotificationMovementDao.deleteAll();
    widget.onComplete();
  }

  void _removeMovement(int index) {
    setState(() {
      _movements[index].dispose();
      _movements.removeAt(index);
    });
    if (_movements.isEmpty) {
      _dismissAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Loading(context)),
      );
    }

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(automaticallyImplyLeading: false),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                child: Row(
                  children: [
                    if (_isAiProcessing)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    else
                      Icon(
                        Icons.notifications_active_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isAiProcessing
                            ? localizations.savingProgress(
                                _aiProcessingCurrent,
                                _aiProcessingTotal,
                              )
                            : localizations.pendingNotificationsDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PendingMovementCard(
                      movement: _movements[index],
                      resolvedAppName: _resolvedAppNames[_movements[index].appName],
                      onDelete: () => _removeMovement(index),
                      onDisallowApp: () => _disallowApp(index),
                      onExpenseChanged: (isExpense) {
                        setState(() {
                          _movements[index].isExpense = isExpense;
                        });
                      },
                    ),
                  );
                }, childCount: _movements.length),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _isSaving
                    ? localizations.savingProgress(_savingCurrent, _savingTotal)
                    : localizations.saveAll,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
