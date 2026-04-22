import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/category_budget.dart';
import 'package:cashly/data/services/budget_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:svg_flutter/svg.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final BudgetService _service;
  Map<String, double> _budgets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final db = SqliteService().db;
    _service = BudgetService(db.categoryBudgetDao, db.movementValueDao);
    _load();
  }

  Future<void> _load() async {
    final all = await _service.getAll();
    if (!mounted) return;
    setState(() {
      _budgets = {for (final b in all) b.category: b.monthlyLimit};
      _isLoading = false;
    });
  }

  Future<void> _editCategory(String category) async {
    final currentLimit = _budgets[category];
    final controller = TextEditingController(
      text: currentLimit != null ? currentLimit.toStringAsFixed(2) : '',
    );
    final localizations = AppLocalizations.of(context)!;

    final result = await showDialog<_BudgetDialogResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: localizations.budgetMonthlyLimit,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.euro),
          ),
        ),
        actions: [
          if (currentLimit != null)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, _BudgetDialogResult.remove()),
              child: Text(
                localizations.remove,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.replaceAll(',', '.').trim();
              final parsed = double.tryParse(text);
              if (parsed == null || parsed <= 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, _BudgetDialogResult.save(parsed));
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result.removed) {
      await _service.removeBudget(category);
    } else if (result.value != null) {
      await _service.setBudget(category, result.value!);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = localizations.localeName;
    final categories = getTagList(locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.budgetsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  color: theme.colorScheme.primaryContainer.withAlpha(80),
                  child: Text(
                    localizations.budgetsDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final limit = _budgets[cat];
                      final hasBudget = limit != null;
                      return ListTile(
                        leading: SizedBox(
                          width: 32,
                          height: 32,
                          child: SvgPicture.asset(
                            getIconPath(cat),
                            colorFilter: ColorFilter.mode(
                              hasBudget
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        title: Text(cat),
                        subtitle: Text(
                          hasBudget
                              ? localizations
                                  .budgetMonthlyAmount(limit.toStringAsFixed(2))
                              : localizations.budgetNotSet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasBudget
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                hasBudget ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          hasBudget ? Icons.edit : Icons.add_circle_outline,
                        ),
                        onTap: () => _editCategory(cat),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _BudgetDialogResult {
  final double? value;
  final bool removed;
  _BudgetDialogResult._(this.value, this.removed);
  factory _BudgetDialogResult.save(double v) =>
      _BudgetDialogResult._(v, false);
  factory _BudgetDialogResult.remove() => _BudgetDialogResult._(null, true);
}
