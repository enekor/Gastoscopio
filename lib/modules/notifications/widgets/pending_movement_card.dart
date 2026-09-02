import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';

class EditablePendingMovement {
  final int? id;
  final String originalText;
  final String appName;
  final String timestamp;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  bool isExpense;
  bool isCreditCard;

  EditablePendingMovement({
    this.id,
    required this.originalText,
    required this.appName,
    required this.timestamp,
    required this.descriptionController,
    required this.amountController,
    this.isExpense = true,
    this.isCreditCard = false,
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
  final Uint8List? appIcon;

  const PendingMovementCard({
    super.key,
    required this.movement,
    required this.onDelete,
    required this.onExpenseChanged,
    this.onDisallowApp,
    this.resolvedAppName,
    this.appIcon,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glass = theme.extension<AppGlass>()!;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: leading app icon (with badge) + name + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AppIconBadge(
                appIcon: appIcon,
                isExpense: movement.isExpense,
                glass: glass,
                scheme: scheme,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedAppName ?? movement.appName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      movement.timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: glass.mutedText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movement.isCreditCard) ...[
                      const SizedBox(height: 8),
                      _CardChip(label: localizations.cardChip, glass: glass),
                    ],
                  ],
                ),
              ),
              if (onDisallowApp != null)
                IconButton(
                  icon: Icon(
                    Icons.notifications_off_outlined,
                    color: glass.mutedText,
                    size: 20,
                  ),
                  tooltip: localizations.disallowApp,
                  onPressed: onDisallowApp,
                  visualDensity: VisualDensity.compact,
                ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: scheme.error,
                  size: 20,
                ),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Editable description field
          TextFormField(
            controller: movement.descriptionController,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: localizations.description,
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

          // Editable amount field
          TextFormField(
            controller: movement.amountController,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: localizations.amount,
              isDense: true,
              prefixText: '€ ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.pleaseEnterAmount;
              }
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) {
                return localizations.pleaseEnterValidAmountGreaterThanZero;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Expense/Income toggle (true = Gasto/expense)
          AppSegmentedControl<bool>(
            selected: movement.isExpense,
            onChanged: onExpenseChanged,
            segments: [
              (
                value: true,
                label: localizations.expense,
                icon: Icons.remove_circle_outline,
              ),
              (
                value: false,
                label: localizations.income,
                icon: Icons.add_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Leading app icon with a small status badge (expense/income colour).
class _AppIconBadge extends StatelessWidget {
  final Uint8List? appIcon;
  final bool isExpense;
  final AppGlass glass;
  final ColorScheme scheme;

  const _AppIconBadge({
    required this.appIcon,
    required this.isExpense,
    required this.glass,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = isExpense ? glass.expenseColor : glass.incomeColor;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: glass.glassFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glass.glassBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: appIcon != null
                ? Image.memory(appIcon!, fit: BoxFit.cover)
                : Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: glass.mutedText,
                  ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(
                isExpense ? Icons.remove : Icons.add,
                size: 10,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green "TARJETA" chip for credit-card movements.
class _CardChip extends StatelessWidget {
  final String label;
  final AppGlass glass;

  const _CardChip({required this.label, required this.glass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: glass.incomeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(glass.pillRadius),
        border: Border.all(color: glass.incomeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card, size: 14, color: glass.incomeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: glass.incomeColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
