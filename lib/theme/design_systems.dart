import 'package:flutter/material.dart';

enum DesignSystemType { ethereal, obsidian }

abstract class DesignSystem {
  Color get primary;
  Color get onPrimary;
  Color get secondary;
  Color get onSecondary;
  Color get tertiary;
  Color get background;
  Color get surface;
  Color get onSurface;
  Color get outline;
  Color get outlineVariant;
  double get borderRadius;
  bool get useGlass;
}

class EtherealLedger extends DesignSystem {
  @override Color get primary => const Color(0xFF6366F1); // Indigo
  @override Color get onPrimary => Colors.white;
  @override Color get secondary => const Color(0xFF10B981); // Emerald
  @override Color get onSecondary => Colors.white;
  @override Color get tertiary => const Color(0xFFF43F5E); // Rose
  @override Color get background => const Color(0xFF0F172A); // Deep Navy
  @override Color get surface => const Color(0xFF1E293B);
  @override Color get onSurface => Colors.white;
  @override Color get outline => const Color(0xFF334155);
  @override Color get outlineVariant => const Color(0xFF475569);
  @override double get borderRadius => 24.0;
  @override bool get useGlass => true;
}

class ObsidianSystem extends DesignSystem {
  @override Color get primary => const Color(0xFFA78BFA); // Soft Violet
  @override Color get onPrimary => Colors.black;
  @override Color get secondary => const Color(0xFFF4F4F5); // Zinc 100
  @override Color get onSecondary => Colors.black;
  @override Color get tertiary => const Color(0xFFEF4444); // Red
  @override Color get background => const Color(0xFF09090B); // Near Black
  @override Color get surface => const Color(0xFF18181B); // Zinc 900
  @override Color get onSurface => const Color(0xFFFAFAFA);
  @override Color get outline => const Color(0xFF27272A); // Zinc 800
  @override Color get outlineVariant => const Color(0xFF3F3F46); // Zinc 700
  @override double get borderRadius => 8.0;
  @override bool get useGlass => false;
}
