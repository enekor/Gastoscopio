import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cashly/classification/classification_service.dart';
import 'package:cashly/classification/locales/locale_config.dart';


class MovementFormScreen extends StatefulWidget {
  final MovementValue? movement;
  bool isExpense;
  final bool forceDebtMode;

  /// When true, renders as a full page (background + safe area) instead of the
  /// compact modal bottom-sheet content.
  final bool asScreen;

  MovementFormScreen({
    super.key,
    this.movement,
    this.isExpense = true,
    this.forceDebtMode = false,
    this.asScreen = false,
  });

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late final _descriptionController = TextEditingController();
  late final _amountController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();
  late String _moneda = '';
  String? _category;
  final _descriptionFocus = FocusNode();
  final _amountFocus = FocusNode();
  bool _showDatePicker = true;
  bool _createAsOneTimeDebt = false;

  @override
  void initState() {
    super.initState();
    if (widget.movement != null) {
      _descriptionController.text = widget.movement!.description;
      _amountController.text = widget.movement!.amount.toStringAsFixed(2);
      widget.isExpense = widget.movement!.isExpense;

      SqliteService().db.monthDao.findMonthById(widget.movement!.monthId).then((
        value,
      ) {
        _selectedDate = DateTime(value!.year, value.month, widget.movement!.day);
      });

      _category = widget.movement!.category;
      _showDatePicker = false;
    }
    if (widget.forceDebtMode && widget.movement == null) {
      _createAsOneTimeDebt = true;
    }
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _descriptionFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _migrateMonth(BuildContext context) async {
    DateTime month = DateTime.now();
    final DateTime? picked = await showDatePicker(
      helpText: AppLocalizations.of(context)!.selectMonthToMigrate,
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        month = picked;
      });
    }

    FinanceService financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );

    await financeService.migrateMonth(
      context,
      widget.movement!,
      month.month,
      month.year,
    );

    setState(() {
      Navigator.pop(context);
    });
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

  Future<void> _saveMovement(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });
    try {
      String amountText = _amountController.text.trim();
      amountText = amountText.replaceAll(',', '.');
      amountText = amountText.replaceAll(' ', '');
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        if (mounted) {
          Fluttertoast.showToast(
            msg: "❌ Monto inválido",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.pleaseEnterValidAmountGreaterThanZero,
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final db = SqliteService().db;
      final financeService = FinanceService.getInstance(
        db.monthDao,
        db.movementValueDao,
        db.fixedMovementDao,
      );

      int monthId =
          widget.movement?.monthId ??
          await financeService.findMonthByMonthAndYear(
            _selectedDate.month,
            _selectedDate.year,
          );

      if (_category == null) {
        try {
          final locale = LocaleRegistry.get(AppLocalizations.of(context).localeName);
          final result = ClassificationService().suggester.suggest(
            _descriptionController.text,
            locale: locale,
          );
          final generatedCategory = result.tag;

          if (generatedCategory.isEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.categoryNotGenerated),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _category = generatedCategory.isEmpty ? '' : generatedCategory;
        } catch (e) {
          _category = '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.errorGeneratingCategory,
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          LogFileService().appendLog('Error generating category: $e');
        }
      }

      if (widget.movement != null) {
        final movement = MovementValue(
          widget.movement!.id,
          monthId,
          _descriptionController.text,
          amount,
          widget.isExpense,
          _selectedDate.day,
          _category,
        );
        await db.movementValueDao.updateMovementValue(movement);
      } else if (_createAsOneTimeDebt) {
        await financeService.createOneTimeDebt(
          description: _descriptionController.text,
          amount: amount,
          isExpense: widget.isExpense,
          date: _selectedDate,
          category: _category?.trim(),
        );
      } else {
        final movement = MovementValue(
          DateTime.now().millisecondsSinceEpoch,
          monthId,
          _descriptionController.text,
          amount,
          widget.isExpense,
          _selectedDate.day,
          _category?.trim(),
        );
        await db.movementValueDao.insertMovementValue(movement);
      }

      await SharedPreferencesService().haveToUpload();

      if (mounted) {
        await financeService.updateSelectedDate(
          _selectedDate.month,
          _selectedDate.year,
        );
        Fluttertoast.showToast(
          msg: widget.movement != null
              ? AppLocalizations.of(context)!.movementUpdated
              : _createAsOneTimeDebt
                  ? '✅ Deuda puntual creada'
                  : AppLocalizations.of(context)!.movementSaved,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      LogFileService().appendLog('Error saving movement: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: "❌ Error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.generalError}: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final content = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          // Gasto / Ingreso
          AppSegmentedControl<bool>(
            segments: [
              (value: true, label: localizations.expense, icon: Icons.remove),
              (value: false, label: localizations.income, icon: Icons.add),
            ],
            selected: widget.isExpense,
            onChanged: (v) => setState(() => widget.isExpense = v),
          ),
          const SizedBox(height: 16),
          _buildNameCard(context, localizations),
          const SizedBox(height: 16),
          _buildValueCard(context),
          const SizedBox(height: 16),
          _buildDateRow(context, localizations),
          if (widget.movement == null && !widget.forceDebtMode) ...[
            const SizedBox(height: 20),
            Text(
              localizations.movementType,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AppSegmentedControl<bool>(
              segments: [
                (value: false, label: localizations.directExpense, icon: null),
                (value: true, label: localizations.oneTimeDebtLabel, icon: null),
              ],
              selected: _createAsOneTimeDebt,
              onChanged: (v) => setState(() => _createAsOneTimeDebt = v),
            ),
          ],
          const SizedBox(height: 28),
          PrimaryPillButton(
            label: widget.movement != null
                ? localizations.save
                : widget.isExpense
                    ? localizations.saveExpense
                    : localizations.saveIncome,
            icon: Icons.check_circle_outline,
            loading: _isLoading,
            onPressed: () => _saveMovement(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (widget.asScreen) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(20), child: content),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.asScreen)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.newMovementTitle,
            textAlign: widget.asScreen ? TextAlign.center : TextAlign.start,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (!widget.asScreen)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildNameCard(BuildContext context, AppLocalizations localizations) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.description,
            style: TextStyle(color: glass.mutedText, fontSize: 13),
          ),
          TextFormField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              hintText: localizations.expenseNameHint,
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? localizations.pleaseEnterDescription
                : null,
          ),
          const SizedBox(height: 8),
          ActionChip(
            avatar: Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
            label: Text(
              _category != null && _category!.isNotEmpty
                  ? _category!
                  : localizations.categoryAiTag,
            ),
            onPressed: _pickCategory,
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.valueLabel,
            style: TextStyle(color: glass.mutedText, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _moneda,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocus,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0.00',
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterAmount;
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return AppLocalizations.of(context)!.pleaseEnterValidAmount;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context, AppLocalizations localizations) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    if (!_showDatePicker) {
      return GlassCard(
        onTap: () => _migrateMonth(context),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: scheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(localizations.migrateMonth),
          ],
        ),
      );
    }
    return GlassCard(
      onTap: () => _selectDate(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.date,
                style: TextStyle(color: glass.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
