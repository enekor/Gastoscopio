import 'package:flutter/material.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cashly/common/tag_list.dart';

class MovementTile extends StatelessWidget {
  final MovementValue movement;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget expandedContent;
  final String currency;

  const MovementTile({
    required this.movement,
    required this.isExpanded,
    required this.onTap,
    required this.expandedContent,
    required this.currency,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              _getCategoryIconPath(movement.category ?? 'miscellaneous'),
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          title: Text(
            movement.description,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: movement.category != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    movement.category!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${movement.amount.toStringAsFixed(2)} $currency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: movement.isExpense
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Día ${movement.day}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: expandedContent,
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOutCubic,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withAlpha(20),
            thickness: 4,
            radius: BorderRadius.circular(25),
          ),
        ),
      ],
    );
  }
}
