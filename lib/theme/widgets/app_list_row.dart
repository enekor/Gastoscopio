import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';

/// Movement / debt / expense row: circular icon, title, subtitle/chip, trailing.
class AppListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? chip;
  final IconData? leadingIcon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.chip,
    this.leadingIcon,
    this.leading,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          leading ??
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadingIcon ?? Icons.receipt_long,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null || chip != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (chip != null) chip!,
                      if (chip != null && subtitle != null)
                        const SizedBox(width: 8),
                      if (subtitle != null)
                        Flexible(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: glass.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
