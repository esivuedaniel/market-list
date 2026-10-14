import 'package:drift/drift.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';

class SettingsMapper {
  const SettingsMapper();

  AppSettings toEntity(AppSettingsRow row) {
    return AppSettings(
      defaultCurrency: CurrencyCode.fromCode(row.defaultCurrencyCode),
      themeMode: AppThemeMode.fromString(row.themeMode),
      onboardingDone: row.onboardingDone,
    );
  }

  AppSettingsTableCompanion toCompanion(AppSettings settings) {
    return AppSettingsTableCompanion.insert(
      id: const Value(1),
      defaultCurrencyCode: settings.defaultCurrency.code,
      themeMode: Value(settings.themeMode.name),
      onboardingDone: Value(settings.onboardingDone),
    );
  }
}
