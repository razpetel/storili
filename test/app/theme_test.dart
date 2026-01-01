import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('AppTypography', () {
    testWidgets('cardTitle uses Fredoka family', (tester) async {
      final style = AppTypography.cardTitle;
      expect(style.fontFamily, startsWith('Fredoka'));
    });

    testWidgets('cardTitle is 22sp semibold', (tester) async {
      final style = AppTypography.cardTitle;
      expect(style.fontSize, 22);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('body uses Nunito family', (tester) async {
      final style = AppTypography.body;
      expect(style.fontFamily, startsWith('Nunito'));
    });
  });
}
