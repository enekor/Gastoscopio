import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

/// Frosted translucent card. Falls back to a flat surface in the Obsidian theme
/// (blurSigma == 0).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? radius;
  final bool gradientBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius,
    this.gradientBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final r = radius ?? glass.cardRadius;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass.glassFill,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: glass.glassBorder, width: 1),
      ),
      child: child,
    );
    final blurred = glass.blurSigma > 0
        ? ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glass.blurSigma,
                sigmaY: glass.blurSigma,
              ),
              child: content,
            ),
          )
        : content;
    if (onTap == null) return blurred;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: blurred,
      ),
    );
  }
}
