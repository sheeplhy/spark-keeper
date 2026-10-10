import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF071A2B);
  static const surface = Color(0xFF0B263B);
  static const surfaceHigh = Color(0xFF10334D);
  static const lightSurface = Color(0xFFF5F9F8);
  static const lightSurfaceMuted = Color(0xFFE9F2F0);
  static const ink = Color(0xFF102638);
  static const inkMuted = Color(0xFF6D7D89);
  static const primary = Color(0xFF19D6A5);
  static const secondary = Color(0xFF16B8D4);
  static const text = Color(0xFFEAF1F5);
  static const muted = Color(0xFF92A4B2);
  static const outline = Color(0xFF1A4E69);
  static const warning = Color(0xFFFFC857);
  static const danger = Color(0xFFFF6B7A);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          onSurface: AppColors.text,
          outline: AppColors.outline,
          error: AppColors.danger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamilyFallback: const ['Microsoft YaHei', 'Noto Sans CJK SC'],
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.background,
          backgroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
