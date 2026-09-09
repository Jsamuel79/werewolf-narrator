import 'package:flutter/material.dart';

/// Visual identity of the app: a dark, low-glare palette so the narrator can
/// read the screen at a dimly lit table without blinding the players.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF7C4DFF);

  static const Color villageColor = Color(0xFF4CAF50);
  static const Color werewolfColor = Color(0xFFE53935);
  static const Color soloColor = Color(0xFFFFB300);
  static const Color deadColor = Color(0xFF757575);
  static const Color loverColor = Color(0xFFEC407A);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF12101A),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1B1725),
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B1725),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Color(0xFF1B1725),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.3),
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
