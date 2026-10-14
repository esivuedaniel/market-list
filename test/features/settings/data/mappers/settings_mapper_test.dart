import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/data/mappers/settings_mapper.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';

void main() {
  const mapper = SettingsMapper();

  group('SettingsMapper', () {
    test('FR-080 toEntity maps AppSettingsRow to AppSettings', () {
      const row = AppSettingsRow(
        id: 1,
        defaultCurrencyCode: 'EUR',
        themeMode: 'dark',
        onboardingDone: true,
      );

      final settings = mapper.toEntity(row);

      expect(settings.defaultCurrency, CurrencyCode.eur);
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.onboardingDone, isTrue);
    });

    test('FR-080 toCompanion maps AppSettings to AppSettingsTableCompanion', () {
      const settings = AppSettings(
        defaultCurrency: CurrencyCode.gbp,
        themeMode: AppThemeMode.light,
        onboardingDone: false,
      );

      final companion = mapper.toCompanion(settings);

      expect(companion.id.value, 1);
      expect(companion.defaultCurrencyCode.value, 'GBP');
      expect(companion.themeMode.value, 'light');
      expect(companion.onboardingDone.value, isFalse);
    });
  });
}
