import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Recurrence kind for the create form.
enum _RecurringKind { expense, debt }

/// Pushed screen: create a new recurring movement (fixed expense) or a
/// recurring monthly debt. Matches the Stitch "Nuevo" recurrente design.
class RecurringFormScreen extends StatefulWidget {
  const RecurringFormScreen({super.key});

  @override
  State<RecurringFormScreen> createState() => _RecurringFormScreenState();
}

class _RecurringFormScreenState extends State<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  _RecurringKind _kind = _RecurringKind.expense;
  String? _category;
  int _chargeDay = 1;
  String _moneda = '€';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final locale = AppLocalizations.of(context).localeName;
    final tags = getTagList(locale);
    final scheme = Theme.of(context).colorScheme;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainerHigh,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (t) => ActionChip(
                    label: Text(t),
                    onPressed: () => Navigator.pop(context, t),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _category = selected;
      });
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    String amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (name.isEmpty) {
      _toastError('Introduce un nombre');
      return;
    }
    if (amount == null || amount <= 0) {
      _toastError('Introduce un importe válido');
      return;
    }
    if (_chargeDay < 1 || _chargeDay > 31) {
      _toastError('El día debe estar entre 1 y 31');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_kind == _RecurringKind.expense) {
        await SqliteService().db.fixedMovementDao.insertFixedMovement(
          FixedMovement(null, name, amount, true, _chargeDay, _category),
        );
        await SharedPreferencesService().haveToUpload();
      } else {
        final financeService = FinanceService.getInstance(
          SqliteService().db.monthDao,
          SqliteService().db.movementValueDao,
          SqliteService().db.fixedMovementDao,
        );
        await financeService.createMonthlyDebtDefinition(
          description: name,
          amount: amount,
          isExpense: true,
          day: _chargeDay,
          category: _category,
        );
      }

      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '✅ Recurrente guardado',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.pop(context, true);
    } catch (e) {
      LogFileService().appendLog('Error creating recurring movement: $e');
      if (!mounted) return;
      _toastError('Error al guardar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.generalError}: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toastError(String msg) {
    Fluttertoast.showToast(
      msg: '❌ $msg',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
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
        title: Text(
          AppLocalizations.of(context)!.newMovementTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAmountField(context),
                  const SizedBox(height: 24),
                  _buildNameCategoryCard(context),
                  const SizedBox(height: 20),
                  AppSegmentedControl<_RecurringKind>(
                    segments: [
                      (
                        value: _RecurringKind.expense,
                        label: AppLocalizations.of(context)!.recurringExpense,
                        icon: null,
                      ),
                      (
                        value: _RecurringKind.debt,
                        label: AppLocalizations.of(context)!.recurringDebt,
                        icon: null,
                      ),
                    ],
                    selected: _kind,
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                  const SizedBox(height: 20),
                  _buildScheduleCard(context),
                  const SizedBox(height: 32),
                  PrimaryPillButton(
                    label: AppLocalizations.of(context)!.saveRecurring,
                    icon: Icons.check_circle_outline,
                    loading: _isLoading,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Column(
      children: [
        Text(
          'Monto del Movimiento',
          style: TextStyle(color: glass.mutedText, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _moneda,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: glass.mutedText,
              ),
            ),
            const SizedBox(width: 10),
            IntrinsicWidth(
              child: TextFormField(
                controller: _amountController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  color: scheme.onSurface,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0.00',
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameCategoryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final hasCategory = _category != null && _category!.isNotEmpty;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.name.toUpperCase(),
            style: TextStyle(
              color: glass.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(glass.pillRadius),
              border: Border.all(color: glass.glassBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: _nameController,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: 'Ej. Netflix, Alquiler',
                hintStyle: TextStyle(color: glass.mutedText),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.categoryLabel.toUpperCase(),
            style: TextStyle(
              color: glass.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(glass.pillRadius),
              onTap: _pickCategory,
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(glass.pillRadius),
                  border: Border.all(color: glass.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasCategory
                            ? _category!
                            : AppLocalizations.of(context)!.selectCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasCategory
                              ? scheme.onSurface
                              : glass.mutedText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: glass.mutedText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.scheduleLabel,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.frequency,
                      style: TextStyle(
                        color: glass.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFrequencyField(context),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.chargeDay,
                      style: TextStyle(
                        color: glass.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDayField(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    // Informational only: recurring definitions are always monthly.
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(glass.pillRadius),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.monthly,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: glass.mutedText),
        ],
      ),
    );
  }

  Widget _buildDayField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(glass.pillRadius),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _chargeDay,
                isExpanded: true,
                isDense: true,
                icon: Icon(Icons.calendar_today, size: 18, color: glass.mutedText),
                dropdownColor: scheme.surfaceContainerHigh,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  for (int d = 1; d <= 31; d++)
                    DropdownMenuItem<int>(
                      value: d,
                      child: Text('Día $d'),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _chargeDay = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
