import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

/// Full-screen background: theme gradient + optional user image fading out.
///
/// When there is no background image we use a paint-only [DecoratedBox] so the
/// child inherits the parent's constraints unchanged. Wrapping a scrollable in a
/// Container+Stack (loose constraints) made pushed screens (e.g. the credit-card
/// screen) scroll infinitely; DecoratedBox avoids that.
class AppBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  const AppBackground({super.key, required this.child, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (!hasImage) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: glass.backgroundGradient),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: glass.backgroundGradient),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
