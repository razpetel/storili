import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storili/app/theme.dart';

void main() {
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
