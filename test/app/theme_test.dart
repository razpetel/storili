import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/theme.dart';

void main() {
  group('AppColors', () {
    test('primary is warm cream', () {
      expect(AppColors.primary, const Color(0xFFF5E6D3));
    });

    test('accent is friendly orange', () {
      expect(AppColors.accent, const Color(0xFFF97316));
    });

    test('background is light warm', () {
      expect(AppColors.background, const Color(0xFFFDF8F3));
    });

    test('textPrimary is deep brown', () {
      expect(AppColors.textPrimary, const Color(0xFF3D2914));
    });
  });

  group('StoriliTheme', () {
    test('lightTheme returns a ThemeData', () {
      final theme = StoriliTheme.lightTheme;
      expect(theme, isA<ThemeData>());
    });

    test('lightTheme uses correct primary color', () {
      final theme = StoriliTheme.lightTheme;
      expect(theme.colorScheme.primary, equals(StoriliTheme.primaryColor));
    });

    test('lightTheme uses rounded card shapes', () {
      final theme = StoriliTheme.lightTheme;
      final cardTheme = theme.cardTheme;
      expect(cardTheme.shape, isA<RoundedRectangleBorder>());
    });
  });
}
