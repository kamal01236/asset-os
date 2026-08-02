import 'package:flutter/material.dart';

import '../models/entities.dart';

class AppTheme {
  const AppTheme._();

  static const Color available = Color(0xFF2E7D32);
  static const Color rented = Color(0xFF1565C0);
  static const Color dueToday = Color(0xFFEF6C00);
  static const Color overdue = Color(0xFFC62828);
  static const Color archived = Color(0xFF757575);

  static ThemeData build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006D77),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFB),
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
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade300,
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
}
