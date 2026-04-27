import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class ScannedMovement {
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  bool isExpense;
  String? category;

  ScannedMovement({
    required this.descriptionController,
    required this.amountController,
    this.isExpense = true,
    this.category,
  });

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }
}

class ScannedMovementCard extends StatelessWidget {
  final ScannedMovement movement;
  final VoidCallback onDelete;
  final ValueChanged<bool> onExpenseChanged;

  const ScannedMovementCard({
    super.key,
    required this.movement,
    required this.onDelete,
    required this.onExpenseChanged,
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
            Row(
              children: [
                if (movement.category != null && movement.category!.isNotEmpty)
                  Flexible(
                    child: Chip(
                      avatar: const Icon(Icons.label_outline, size: 16),
                      label: Text(
                        movement.category!,
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const Spacer(),
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
