import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF6A8CAF);
  static const Color secondaryColor = Color(0xFFD4B499);
  static const Color accentColor = Color(0xFFE57373);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color darkBackgroundColor = Color(0xFF121212);
}

extension ColorExtension on Color {
  Color get lighten => Color.fromARGB(
        alpha,
        red + ((255 - red) ~/ 2),
        green + ((255 - green) ~/ 2),
        blue + ((255 - blue) ~/ 2),
      );

  Color get darken => Color.fromARGB(
        alpha,
        red ~/ 2,
        green ~/ 2,
        blue ~/ 2,
      );
}

// Tema claro
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTheme.primaryColor,
      brightness: Brightness.light,
      secondary: AppTheme.secondaryColor,
      tertiary: AppTheme.accentColor,
      background: AppTheme.backgroundColor,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // Tema para calendarios
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    // Tema para diálogos
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
    ),
  );
}

// Tema oscuro
ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTheme.primaryColor,
      brightness: Brightness.dark,
      secondary: AppTheme.secondaryColor,
      tertiary: AppTheme.accentColor,
      background: AppTheme.darkBackgroundColor,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppTheme.darkBackgroundColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // Tema para diálogos en modo oscuro
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      backgroundColor: const Color(0xFF1E1E1E),
    ),
    // Asegurarnos que los colores están bien definidos
    scaffoldBackgroundColor: AppTheme.darkBackgroundColor,
    cardColor: const Color(0xFF1E1E1E),
  );
}
