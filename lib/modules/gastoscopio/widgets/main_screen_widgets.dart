import 'package:flutter/material.dart';

Widget AnimatedCard(
  BuildContext context, {
  required Widget hiddenWidget,
  required bool isExpanded,
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
            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                firstChild: Container(),
                secondChild: Padding(
                  padding: const EdgeInsets.all(16.0),
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
