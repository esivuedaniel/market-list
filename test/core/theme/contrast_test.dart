import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/theme/app_colors.dart';
import 'package:market_list/core/theme/app_theme.dart';

double _relativeLuminance(Color color) {
  double transform(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = transform(color.r);
  final g = transform(color.g);
  final b = transform(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('G5/AS-11 Contrast tests for light and dark themes', () {
    test('G5 light palette pairs meet WCAG AA standards', () {
      final scheme = AppTheme.lightColorScheme;
      const scaffold = AppTheme.lightScaffold;
      final appColors = AppColors.light;

      // Text on primary meets at least 4.5:1 (PRD cites ~6.4:1)
      expect(_contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5));

      // onPrimaryContainer on primaryContainer
      expect(_contrastRatio(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5));

      // primaryText on light scaffold and surface meets at least 4.5:1
      expect(_contrastRatio(appColors.primaryText, scaffold),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(appColors.primaryText, scheme.surface),
          greaterThanOrEqualTo(4.5));

      // onSurface on surface and scaffold
      expect(_contrastRatio(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(scheme.onSurface, scaffold),
          greaterThanOrEqualTo(4.5));

      // onSurfaceVariant on surface and scaffold
      expect(_contrastRatio(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(scheme.onSurfaceVariant, scaffold),
          greaterThanOrEqualTo(4.5));

      // onError on error
      expect(_contrastRatio(scheme.onError, scheme.error),
          greaterThanOrEqualTo(4.5));

      // Snackbar text and action on inverseSurface
      expect(_contrastRatio(scheme.onInverseSurface, scheme.inverseSurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(scheme.inversePrimary, scheme.inverseSurface),
          greaterThanOrEqualTo(4.5));
    });

    test('AS-11 dark palette pairs meet WCAG AA standards', () {
      final scheme = AppTheme.darkColorScheme;
      const scaffold = AppTheme.darkScaffold;
      final appColors = AppColors.dark;

      // onPrimary on primary
      expect(_contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5));

      // onPrimaryContainer on primaryContainer
      expect(_contrastRatio(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5));

      // primaryText on dark scaffold and surface
      expect(_contrastRatio(appColors.primaryText, scaffold),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(appColors.primaryText, scheme.surface),
          greaterThanOrEqualTo(4.5));

      // onSurface on surface and scaffold
      expect(_contrastRatio(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(scheme.onSurface, scaffold),
          greaterThanOrEqualTo(4.5));

      // onSurfaceVariant on surface and scaffold
      expect(_contrastRatio(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(scheme.onSurfaceVariant, scaffold),
          greaterThanOrEqualTo(4.5));

      // onError on error
      expect(_contrastRatio(scheme.onError, scheme.error),
          greaterThanOrEqualTo(4.5));

      // Snackbar text and action on inverseSurface
      expect(_contrastRatio(scheme.onInverseSurface, scheme.inverseSurface),
          greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(scheme.inversePrimary, scheme.inverseSurface),
          greaterThanOrEqualTo(4.5));
    });
  });
}
