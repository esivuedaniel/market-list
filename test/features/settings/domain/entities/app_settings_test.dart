import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';

void main() {
  group('AppSettings entity', () {
    test('FR-090 supports equality and copyWith', () {
      const settings = AppSettings(
        defaultCurrency: CurrencyCode.usd,
        themeMode: AppThemeMode.system,
        onboardingDone: false,
      );

      final updated = settings.copyWith(
        defaultCurrency: CurrencyCode.ngn,
        themeMode: AppThemeMode.dark,
        onboardingDone: true,
      );

      expect(updated.defaultCurrency, CurrencyCode.ngn);
      expect(updated.themeMode, AppThemeMode.dark);
      expect(updated.onboardingDone, isTrue);

      final same = settings.copyWith();
      expect(same, equals(settings));
    });
  });

  group('AppThemeMode enum', () {
    test('FR-091 fromString parses light, dark, system, and defaults to system', () {
      expect(AppThemeMode.fromString('light'), AppThemeMode.light);
      expect(AppThemeMode.fromString('DARK'), AppThemeMode.dark);
      expect(AppThemeMode.fromString('system'), AppThemeMode.system);
      expect(AppThemeMode.fromString('invalid'), AppThemeMode.system);
    });
  });
}
