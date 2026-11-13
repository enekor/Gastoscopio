import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

/// Card surface for the design system.
///
/// Note: we intentionally avoid a real [BackdropFilter] blur here. Stacking many
/// backdrop-blurred cards is very expensive on mobile and caused noticeable lag
/// on the blur-based themes. Instead we composite the translucent [AppGlass.glassFill]
/// over the theme surface to get a visible "glass" panel at near-zero cost.
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
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final r = radius ?? glass.cardRadius;
    final fill = Color.alphaBlend(glass.glassFill, scheme.surface);

    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: glass.glassBorder, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
