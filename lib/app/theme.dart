import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Claymorphism color palette for Storili.
/// Warm storybook colors optimized for children ages 3-5.
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFFF5E6D3);      // Warm cream
  static const Color secondary = Color(0xFF8B7355);    // Soft brown
  static const Color accent = Color(0xFFF97316);       // Friendly orange

  // Background
  static const Color background = Color(0xFFFDF8F3);   // Light warm

  // Text
  static const Color textPrimary = Color(0xFF3D2914);  // Deep brown
  static const Color textSecondary = Color(0xFF6B5344); // Medium brown

  // Shadows (claymorphism)
  static const Color shadowOuter = Color(0xFFFDBCB4);  // Soft peach
  static const Color shadowInner = Color(0xFFFFE4D6);  // Light peach

  // Legacy (keep for backward compatibility)
  static const Color capyBrown = Color(0xFF8B5E3C);
  static const Color forestGreen = Color(0xFF4A7C59);
}

/// Typography using Fredoka (headings) and Nunito (body).
/// Playful, rounded fonts suitable for children's apps.
class AppTypography {
  AppTypography._();

  static TextStyle get appTitle => GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardTitle => GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );
}

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
      cardTheme: CardThemeData(
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
