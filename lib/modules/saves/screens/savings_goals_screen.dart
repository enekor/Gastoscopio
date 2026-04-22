import 'package:cashly/data/dao/savings_goal_dao.dart';
import 'package:cashly/data/models/savings_goal.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  late final SavingsGoalDao _dao;
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;
  String _currency = '€';

  static const _iconChoices = <(String, IconData)>[
    ('flight', Icons.flight),
    ('directions_car', Icons.directions_car),
    ('home', Icons.home_outlined),
    ('favorite', Icons.favorite_outline),
    ('phone_android', Icons.phone_android),
    ('school', Icons.school_outlined),
    ('card_giftcard', Icons.card_giftcard),
    ('savings', Icons.savings_outlined),
    ('celebration', Icons.celebration_outlined),
    ('pets', Icons.pets),
    ('medical_services', Icons.medical_services_outlined),
    ('shield', Icons.shield_outlined),
  ];

  static IconData iconForName(String name) {
    return _iconChoices
        .firstWhere(
          (e) => e.$1 == name,
          orElse: () => ('savings', Icons.savings_outlined),
        )
        .$2;
  }

  @override
  void initState() {
    super.initState();
    _dao = SqliteService().db.savingsGoalDao;
    _load();
  }

  Future<void> _load() async {
    final currency = await SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency);
    final goals = await _dao.findAll();
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _currency = currency ?? '€';
      _isLoading = false;
    });
  }

  Future<void> _openEditor({SavingsGoal? goal}) async {
    final result = await showModalBottomSheet<SavingsGoal>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GoalEditor(goal: goal, currency: _currency),
    );

    if (result == null) return;

    if (goal == null) {
      await _dao.insertGoal(result);
    } else {
      await _dao.updateGoal(result);
    }
    await _load();
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.deleteGoalTitle),
        content: Text(localizations.deleteGoalConfirmation(goal.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dao.deleteGoal(goal);
      await _load();
    }
  }

  Future<void> _updateAmount(SavingsGoal goal) async {
    final controller = TextEditingController(
      text: goal.currentAmount.toStringAsFixed(2),
    );
    final localizations = AppLocalizations.of(context)!;
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(goal.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: localizations.goalCurrentAmount,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.savings_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.replaceAll(',', '.').trim();
              final parsed = double.tryParse(text);
              if (parsed == null || parsed < 0) return;
              Navigator.pop(ctx, parsed);
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
    if (result != null) {
      await _dao.updateGoal(goal.copyWith(currentAmount: result));
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.savingsGoalsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(localizations.addGoal),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _goals.length,
                  itemBuilder: (ctx, i) {
                    final goal = _goals[i];
                    return _buildGoalCard(context, goal);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 72,
              color: theme.colorScheme.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noGoalsYet,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.noGoalsDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoal goal) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final progress = goal.progress;
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    final color = goal.isCompleted
        ? Colors.green
        : progress >= 0.75
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary;

    return Card(
      color: theme.colorScheme.secondary.withAlpha(25),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _updateAmount(goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withAlpha(40),
                    child: Icon(iconForName(goal.iconName), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (goal.isCompleted)
                          Text(
                            localizations.goalCompleted,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            localizations.goalRemaining(
                              remaining.toStringAsFixed(2) + _currency,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _openEditor(goal: goal);
                      if (value == 'delete') _deleteGoal(goal);
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(localizations.edit),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete,
                              size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Text(localizations.delete,
                              style:
                                  TextStyle(color: theme.colorScheme.error)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${goal.currentAmount.toStringAsFixed(2)}$_currency / ${goal.targetAmount.toStringAsFixed(2)}$_currency',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
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
}

class _GoalEditor extends StatefulWidget {
  final SavingsGoal? goal;
  final String currency;

  const _GoalEditor({this.goal, required this.currency});

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _currentCtrl;
  String _iconName = 'savings';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.goal?.name ?? '');
    _targetCtrl = TextEditingController(
      text: widget.goal?.targetAmount.toStringAsFixed(2) ?? '',
    );
    _currentCtrl = TextEditingController(
      text: widget.goal?.currentAmount.toStringAsFixed(2) ?? '0',
    );
    _iconName = widget.goal?.iconName ?? 'savings';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    final current = double.tryParse(_currentCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || target == null || target <= 0 || current == null || current < 0) {
      return;
    }
    final result = SavingsGoal(
      id: widget.goal?.id,
      name: name,
      targetAmount: target,
      currentAmount: current,
      iconName: _iconName,
      createdAt: widget.goal?.createdAt ?? DateTime.now().toIso8601String(),
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.goal == null
                  ? localizations.newGoal
                  : localizations.editGoalSheet,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: localizations.goalName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: localizations.goalTargetAmount,
                border: const OutlineInputBorder(),
                suffixText: widget.currency,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: localizations.goalCurrentAmount,
                border: const OutlineInputBorder(),
                suffixText: widget.currency,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.goalIcon,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _SavingsGoalsScreenState._iconChoices.map((e) {
                final selected = _iconName == e.$1;
                return GestureDetector(
                  onTap: () => setState(() => _iconName = e.$1),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest
                              .withAlpha(120),
                    ),
                    child: Icon(
                      e.$2,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(localizations.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
