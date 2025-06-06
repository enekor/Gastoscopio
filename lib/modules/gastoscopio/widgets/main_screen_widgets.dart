import 'package:flutter/material.dart';

Widget AnimatedCard(
  BuildContext context, {
  required Widget hiddenWidget,
  Widget? leadingWidget,
  required bool isExpanded,
  Color? color,
}) {
  return StatefulBuilder(
    builder: (context, setState) {
      return GestureDetector(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color:
                color ?? Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              leadingWidget ?? Container(),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: Container(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 5.0,
                  ),
                  child: hiddenWidget,
                ),
                crossFadeState:
                    isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
              ),
            ],
          ),
        ),
      );
    },
  );
}
