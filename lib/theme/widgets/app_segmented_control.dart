import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

typedef SegmentSpec<T> = ({T value, String label, IconData? icon});

/// Pill-style segmented control (2-3 options) matching the Stitch design.
class AppSegmentedControl<T> extends StatelessWidget {
  final List<SegmentSpec<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(glass.pillRadius),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        children: segments.map((s) {
          final isSel = s.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(s.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(glass.pillRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.icon != null) ...[
                      Icon(
                        s.icon,
                        size: 18,
                        color: isSel ? scheme.onPrimary : glass.mutedText,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        s.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSel ? scheme.onPrimary : glass.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
