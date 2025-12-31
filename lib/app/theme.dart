import 'package:flutter/material.dart';

class StoriliTheme {
  StoriliTheme._();

  // Warm, child-friendly colors
  static const Color primaryColor = Color(0xFF8B5E3C); // Capy brown
  static const Color secondaryColor = Color(0xFF4A7C59); // Forest green
  static const Color backgroundColor = Color(0xFFFFF8F0); // Warm cream
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE57373);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D2D2D),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2D2D),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }
}
