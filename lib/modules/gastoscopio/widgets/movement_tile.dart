import 'package:flutter/material.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/amount_text.dart';

class MovementTile extends StatelessWidget {
  final MovementValue movement;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget expandedContent;
  final String currency;
  final VoidCallback? onLongPress;

  const MovementTile({
    required this.movement,
    required this.isExpanded,
    required this.onTap,
    required this.expandedContent,
    required this.currency,
    this.onLongPress,
    Key? key,
  }) : super(key: key);

  String _getCategoryIconPath(String category) {
    try {
      return getIconPath(category);
    } catch (e) {
      return 'assets/icons/miscellaneous.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
            onLongPress: onLongPress,
            onTap: onTap,
            child: Row(
              children: [
                // Circular category icon
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    _getCategoryIconPath(movement.category ?? 'miscellaneous'),
                    colorFilter: ColorFilter.mode(
                      scheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + category chip
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (movement.category != null &&
                              movement.category!.isNotEmpty)
                            _CategoryChip(label: movement.category!),
                          if (movement.category != null &&
                              movement.category!.isNotEmpty)
                            const SizedBox(width: 8),
                          Text(
                            'Día ${movement.day}',
                            style: TextStyle(
                              color: glass.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trailing signed amount
                AmountText(
                  amount: movement.amount,
                  currency: currency,
                  isExpense: movement.isExpense,
                  signed: true,
                  fontSize: 16,
                ),
              ],
            ),
          ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: expandedContent,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(glass.pillRadius),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: glass.mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
