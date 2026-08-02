import 'dart:typed_data';

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
import 'package:intl/intl.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';

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
  final Map<String, Uint8List?> _resolvedAppIcons = {};
  DateTime? _selectedDate;
  List<DateTime> _availableDates = [];

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
              (p) {
                debugPrint('Loading movement: ${p.notificationText}, isCreditCard: ${p.isCreditCard}');
                return EditablePendingMovement(
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
                  isCreditCard: p.isCreditCard,
                );
              },
            )
            .toList();
        
        _updateAvailableDates();
        _isLoading = false;
      });

      // Resolve app names and run AI parsing in parallel
      if (_movements.isNotEmpty && mounted) {
        _resolveAppInfo();
        _runAiParsing(pending.map((p) => p.extractedAmount).toList());
      }
    } catch (e) {
      LogFileService().appendLog('Error loading pending notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateAvailableDates() {
    final dates = _movements.map((m) {
      final dt = DateTime.tryParse(m.timestamp) ?? DateTime.now();
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet().toList();
    
    dates.sort((a, b) => b.compareTo(a)); // Newest first

    setState(() {
      _availableDates = dates;
      if (_availableDates.isNotEmpty) {
        if (_selectedDate == null || !_availableDates.contains(_selectedDate)) {
          _selectedDate = _availableDates.first;
        }
      } else {
        _selectedDate = null;
      }
    });
  }

  List<EditablePendingMovement> get _filteredMovements {
    if (_selectedDate == null) return [];
    return _movements.where((m) {
      final dt = DateTime.tryParse(m.timestamp) ?? DateTime.now();
      return dt.year == _selectedDate!.year &&
             dt.month == _selectedDate!.month &&
             dt.day == _selectedDate!.day;
    }).toList();
  }

  Future<void> _resolveAppInfo() async {
    final uniquePackages = _movements.map((m) => m.appName).toSet();
    final service = NotificationCaptureService();
    for (final pkg in uniquePackages) {
      try {
        final name = await service.getAppName(pkg);
        final icon = await service.getAppIcon(pkg);
        if (mounted) {
          setState(() {
            _resolvedAppNames[pkg] = name;
            _resolvedAppIcons[pkg] = icon;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _disallowApp(int index) async {
    final movement = _movements[index];
    final packageName = movement.appName;
    final appName = _resolvedAppNames[packageName] ?? packageName;
    final isCredit = movement.isCreditCard;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_off_outlined),
        title: Text(AppLocalizations.of(context)!.disallowApp),
        content: Text(
          AppLocalizations.of(context)!.disallowAppConfirmation(appName),
        ),
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

    if (isCredit) {
      await NotificationCaptureService().disallowCreditApp(packageName);
    } else {
      await NotificationCaptureService().disallowApp(packageName);
    }

    // Remove all movements from this app with same credit status
    setState(() {
      _movements
          .where((m) => m.appName == packageName && m.isCreditCard == isCredit)
          .forEach((m) => m.dispose());
      _movements.removeWhere((m) => m.appName == packageName && m.isCreditCard == isCredit);
      _updateAvailableDates();
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

    final movementsToSave = _filteredMovements;
    if (movementsToSave.isEmpty) return;

    setState(() {
      _isSaving = true;
      _savingTotal = movementsToSave.length;
      _savingCurrent = 0;
    });

    final db = SqliteService().db;
    final financeService = FinanceService.getInstance(
      db.monthDao,
      db.movementValueDao,
      db.fixedMovementDao,
    );
    final creditCardService = CreditCardService.getInstance();

    try {
      for (int i = 0; i < movementsToSave.length; i++) {
        setState(() => _savingCurrent = i + 1);

        final m = movementsToSave[i];
        final amount = double.parse(
          m.amountController.text.replaceAll(',', '.'),
        );
        final date = DateTime.tryParse(m.timestamp) ?? DateTime.now();

        if (m.isCreditCard) {
          // Handle credit card expense
          await creditCardService.addExpense(
            m.descriptionController.text,
            amount,
            date,
          );
        } else {
          // Handle normal movement
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
        }

        // Remove from DB and local list
        if (m.id != null) {
          final pModel = await db.pendingNotificationMovementDao.findAll();
          final toDelete = pModel.firstWhere((element) => element.id == m.id);
          await db.pendingNotificationMovementDao.deletePendingMovement(toDelete);
        }
        
        setState(() {
          _movements.remove(m);
          m.dispose();
        });
      }

      await SharedPreferencesService().haveToUpload();

      // Refresh finance data if needed
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

      _updateAvailableDates();
      if (_availableDates.isEmpty) {
        widget.onComplete();
      }
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

  void _removeMovement(int index) async {
    final m = _filteredMovements[index];
    final db = SqliteService().db;
    
    if (m.id != null) {
      final pModel = await db.pendingNotificationMovementDao.findAll();
      final toDelete = pModel.firstWhere((element) => element.id == m.id);
      await db.pendingNotificationMovementDao.deletePendingMovement(toDelete);
    }

    setState(() {
      m.dispose();
      _movements.remove(m);
      _updateAvailableDates();
    });
    
    if (_availableDates.isEmpty) {
      widget.onComplete();
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
            if (_availableDates.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          localizations.selectDateToView,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: _availableDates.map((date) {
                            final isSelected = _selectedDate != null &&
                                date.year == _selectedDate!.year &&
                                date.month == _selectedDate!.month &&
                                date.day == _selectedDate!.day;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(
                                  DateFormat('dd/MM/yyyy').format(date),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedDate = date);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _filteredMovements.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(localizations.noPendingForDate),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final movement = _filteredMovements[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PendingMovementCard(
                            movement: movement,
                            resolvedAppName:
                                _resolvedAppNames[movement.appName],
                            appIcon: _resolvedAppIcons[movement.appName],
                            onDelete: () => _removeMovement(index),
                            onDisallowApp: () => _disallowApp(_movements.indexOf(movement)),
                            onExpenseChanged: (isExpense) {
                              setState(() {
                                movement.isExpense = isExpense;
                              });
                            },
                          ),
                        );
                      }, childCount: _filteredMovements.length),
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
