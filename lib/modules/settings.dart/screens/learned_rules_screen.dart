import 'package:cashly/classification/classification_service.dart';
import 'package:cashly/classification/learned_rules.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Lista de lo aprendido por el modo aprendizaje, con borrado individual.
class LearnedRulesScreen extends StatefulWidget {
  const LearnedRulesScreen({super.key});

  @override
  State<LearnedRulesScreen> createState() => _LearnedRulesScreenState();
}

class _LearnedRulesScreenState extends State<LearnedRulesScreen> {
  final _service = ClassificationService();

  Future<void> _delete(LearnedRule rule) async {
    final localizations = AppLocalizations.of(context);
    await _service.deleteRule(rule.kind, rule.key);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.learnedRuleDeleted),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final tagRules = _service.rules(LearnedRuleKind.tag);
    final nameRules = _service.rules(LearnedRuleKind.name);
    final isEmpty = tagRules.isEmpty && nameRules.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.learnedRulesTitle)),
      body: isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  localizations.learnedRulesEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (tagRules.isNotEmpty)
                  ..._section(context, localizations.learnedTagsSection,
                      Icons.sell_outlined, tagRules),
                if (nameRules.isNotEmpty)
                  ..._section(context, localizations.learnedNamesSection,
                      Icons.badge_outlined, nameRules),
              ],
            ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    IconData icon,
    List<LearnedRule> rules,
  ) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '$title (${rules.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      for (final rule in rules)
        ListTile(
          title: Text(rule.key),
          subtitle: Text(
            rule.alternatives.isEmpty
                ? rule.value
                : '${rule.value}\n${localizations.learnedRuleAlternatives(rule.alternatives.join(', '))}',
          ),
          isThreeLine: rule.alternatives.isNotEmpty,
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: localizations.delete,
            onPressed: () => _delete(rule),
          ),
        ),
    ];
  }
}
