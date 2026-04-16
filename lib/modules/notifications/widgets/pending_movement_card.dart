import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class EditablePendingMovement {
  final int? id;
  final String originalText;
  final String appName;
  final String timestamp;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  bool isExpense;

  EditablePendingMovement({
    this.id,
    required this.originalText,
    required this.appName,
    required this.timestamp,
    required this.descriptionController,
    required this.amountController,
    this.isExpense = true,
  });

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }
}

class PendingMovementCard extends StatelessWidget {
  final EditablePendingMovement movement;
  final VoidCallback onDelete;
  final ValueChanged<bool> onExpenseChanged;
  final VoidCallback? onDisallowApp;
  final String? resolvedAppName;

  const PendingMovementCard({
    super.key,
    required this.movement,
    required this.onDelete,
    required this.onExpenseChanged,
    this.onDisallowApp,
    this.resolvedAppName,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: app name chip + block button + delete button
            Row(
              children: [
                Flexible(
                  child: Chip(
                    avatar: const Icon(Icons.notifications_outlined, size: 16),
                    label: Text(
                      resolvedAppName ?? movement.appName,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Spacer(),
                if (onDisallowApp != null)
                  IconButton(
                    icon: Icon(
                      Icons.notifications_off_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    tooltip: localizations.disallowApp,
                    onPressed: onDisallowApp,
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            // Original notification text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                movement.originalText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Expense/Income toggle
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Text(localizations.expense),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(localizations.income),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {movement.isExpense},
              onSelectionChanged: (Set<bool> selection) {
                onExpenseChanged(selection.first);
              },
            ),
            const SizedBox(height: 12),

            // Description field
            TextFormField(
              controller: movement.descriptionController,
              decoration: InputDecoration(
                labelText: localizations.description,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Amount field
            TextFormField(
              controller: movement.amountController,
              decoration: InputDecoration(
                labelText: localizations.amount,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterAmount;
                }
                final parsed =
                    double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return localizations.pleaseEnterValidAmountGreaterThanZero;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
