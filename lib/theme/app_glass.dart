import 'package:flutter/material.dart';

@immutable
class AppGlass extends ThemeExtension<AppGlass> {
  final Color glassFill;
  final double blurSigma;
  final Color glassBorder;
  final double cardRadius;
  final double pillRadius;
  final Color incomeColor;
  final Color expenseColor;
  final Color mutedText;
  final Gradient backgroundGradient;

  const AppGlass({
    required this.glassFill,
    required this.blurSigma,
    required this.glassBorder,
    required this.cardRadius,
    required this.pillRadius,
    required this.incomeColor,
    required this.expenseColor,
    required this.mutedText,
    required this.backgroundGradient,
  });

  static const AppGlass ethereal = AppGlass(
    glassFill: Color(0x0DFFFFFF), // 5% white
    blurSigma: 20,
    glassBorder: Color(0x14FFFFFF), // 8% white
    cardRadius: 24,
    pillRadius: 999,
    incomeColor: Color(0xFF10B981),
    expenseColor: Color(0xFFFB7185),
    mutedText: Color(0xFFC6C6CD),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF16223B), Color(0xFF0F172A), Color(0xFF0B0B0D)],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  static const AppGlass obsidian = AppGlass(
    glassFill: Color(0xFF18181B),
    blurSigma: 0,
    glassBorder: Color(0xFF27272A),
    cardRadius: 12,
    pillRadius: 10,
    incomeColor: Color(0xFF34D399),
    expenseColor: Color(0xFFEF4444),
    mutedText: Color(0xFFA1A1AA),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C0C0F), Color(0xFF09090B)],
    ),
  );

  @override
  AppGlass copyWith({
    Color? glassFill,
    double? blurSigma,
    Color? glassBorder,
    double? cardRadius,
    double? pillRadius,
    Color? incomeColor,
    Color? expenseColor,
    Color? mutedText,
    Gradient? backgroundGradient,
  }) {
    return AppGlass(
      glassFill: glassFill ?? this.glassFill,
      blurSigma: blurSigma ?? this.blurSigma,
      glassBorder: glassBorder ?? this.glassBorder,
      cardRadius: cardRadius ?? this.cardRadius,
      pillRadius: pillRadius ?? this.pillRadius,
      incomeColor: incomeColor ?? this.incomeColor,
      expenseColor: expenseColor ?? this.expenseColor,
      mutedText: mutedText ?? this.mutedText,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppGlass lerp(ThemeExtension<AppGlass>? other, double t) {
    if (other is! AppGlass) return this;
    return AppGlass(
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      blurSigma: t < 0.5 ? blurSigma : other.blurSigma,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      pillRadius: pillRadius + (other.pillRadius - pillRadius) * t,
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      backgroundGradient:
          t < 0.5 ? backgroundGradient : other.backgroundGradient,
    );
  }
}
