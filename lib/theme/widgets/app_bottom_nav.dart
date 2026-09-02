import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

typedef NavItem = ({IconData icon, IconData selectedIcon, String label});

/// 5-slot bottom navigation: 4 tabs (2 + gap + 2) leaving a centered gap for
/// the docked FAB.
class AppBottomNav extends StatelessWidget {
  final List<NavItem> items; // expect length 4
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final left = items.take(2).toList();
    final right = items.skip(2).toList();

    Widget tab(NavItem item, int index) {
      final sel = index == selectedIndex;
      return Expanded(
        child: InkWell(
          onTap: () => onSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sel ? item.selectedIcon : item.icon,
                color: sel ? scheme.primary : glass.mutedText,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: sel ? scheme.primary : glass.mutedText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: glass.blurSigma > 0
                ? scheme.surface.withValues(alpha: 0.75)
                : scheme.surfaceContainer,
            border: Border(top: BorderSide(color: glass.glassBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                tab(left[0], 0),
                tab(left[1], 1),
                const SizedBox(width: 72), // gap for the FAB
                tab(right[0], 2),
                tab(right[1], 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
