import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/groq_serice.dart';
import 'package:cashly/data/services/log_file_service.dart';
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
                descriptionController:
                    TextEditingController(text: p.notificationText),
                amountController: TextEditingController(
                  text: p.extractedAmount.toStringAsFixed(2),
                ),
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      LogFileService().appendLog('Error loading pending notifications: $e');
      setState(() => _isLoading = false);
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
        final amount =
            double.parse(m.amountController.text.replaceAll(',', '.'));
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
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => '',
              );
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
      return Scaffold(body: Center(child: Loading(context)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.pendingNotifications),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _dismissAll,
            child: Text(
              localizations.dismissAll,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: theme.colorScheme.primaryContainer.withAlpha(80),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localizations.pendingNotificationsDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _movements.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PendingMovementCard(
                      movement: _movements[index],
                      onDelete: () => _removeMovement(index),
                      onExpenseChanged: (isExpense) {
                        setState(() {
                          _movements[index].isExpense = isExpense;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Save button
          SafeArea(
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
                        ? localizations.savingProgress(
                            _savingCurrent,
                            _savingTotal,
                          )
                        : localizations.saveAll,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
