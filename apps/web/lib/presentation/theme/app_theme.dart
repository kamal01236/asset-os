import 'package:flutter/material.dart';

import '../../domain/models/entities.dart';

class AppTheme {
  const AppTheme._();

  /// Hue tokens for status meaning (chip fills / icons). Prefer
  /// [foregroundForStatus] for text on tinted chips so Light/Dark meet WCAG AA.
  static const Color available = Color(0xFF2E7D32);
  static const Color rented = Color(0xFF1565C0);
  static const Color dueToday = Color(0xFFEF6C00);
  static const Color overdue = Color(0xFFC62828);
  static const Color archived = Color(0xFF757575);

  /// AA-safe text on ~14% status tint chips (Light).
  static const Color _availableFgLight = Color(0xFF1B5E20);
  static const Color _rentedFgLight = Color(0xFF0D47A1);
  static const Color _dueTodayFgLight = Color(0xFFBF3600);
  static const Color _overdueFgLight = Color(0xFFB71C1C);
  static const Color _archivedFgLight = Color(0xFF424242);

  /// AA-safe text on ~14% status tint chips (Dark).
  static const Color _availableFgDark = Color(0xFF81C784);
  static const Color _rentedFgDark = Color(0xFF90CAF9);
  static const Color _dueTodayFgDark = Color(0xFFFFB74D);
  static const Color _overdueFgDark = Color(0xFFEF9A9A);
  static const Color _archivedFgDark = Color(0xFFBDBDBD);

  static const Color _seed = Color(0xFF006D77);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final bool isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isLight ? const Color(0xFFF8FAFB) : scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : scheme.surfaceContainerHighest,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static Color colorForStatus(AssetStatus status) {
    switch (status) {
      case AssetStatus.available:
        return available;
      case AssetStatus.rented:
        return rented;
      case AssetStatus.dueToday:
        return dueToday;
      case AssetStatus.overdue:
        return overdue;
      case AssetStatus.archived:
        return archived;
    }
  }

  /// Contrast-safe foreground for status labels on tinted chips / due amounts.
  /// Keeps status hue meaning; does not change [colorForStatus] fill tokens.
  static Color foregroundForStatus(AssetStatus status, Brightness brightness) {
    final bool light = brightness == Brightness.light;
    switch (status) {
      case AssetStatus.available:
        return light ? _availableFgLight : _availableFgDark;
      case AssetStatus.rented:
        return light ? _rentedFgLight : _rentedFgDark;
      case AssetStatus.dueToday:
        return light ? _dueTodayFgLight : _dueTodayFgDark;
      case AssetStatus.overdue:
        return light ? _overdueFgLight : _overdueFgDark;
      case AssetStatus.archived:
        return light ? _archivedFgLight : _archivedFgDark;
    }
  }
}
