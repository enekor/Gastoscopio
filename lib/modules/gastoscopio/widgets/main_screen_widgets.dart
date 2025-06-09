import 'package:flutter/material.dart';

class AnimatedCard extends StatefulWidget {
  final Widget hiddenWidget;
  final Widget? leadingWidget;
  final bool isExpanded;
  final Color? color;
  final VoidCallback? onTap;

  const AnimatedCard({
    super.key,
    required this.hiddenWidget,
    this.leadingWidget,
    required this.isExpanded,
    this.color,
    this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 500);
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _duration, vsync: this);
    _heightFactor = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
      ),
    );
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color:
          widget.color ?? Theme.of(context).colorScheme.primary.withAlpha(70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: widget.isExpanded ? 2 : 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.leadingWidget != null) widget.leadingWidget!,
            AnimatedBuilder(
              animation: _heightFactor,
              builder:
                  (context, child) => ClipRect(
                    child: Align(
                      heightFactor: _heightFactor.value,
                      child: child,
                    ),
                  ),
              child: widget.hiddenWidget,
            ),
          ],
        ),
      ),
    );
  }
}
