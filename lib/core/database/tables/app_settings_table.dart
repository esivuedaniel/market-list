import 'package:drift/drift.dart';

@DataClassName('AppSettingsRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer()();
  TextColumn get defaultCurrencyCode =>
      text().named('default_currency_code')();
  TextColumn get themeMode =>
      text().named('theme_mode').withDefault(const Constant('system'))();
  BoolColumn get onboardingDone =>
      boolean().named('onboarding_done').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (id = 1)',
        'CHECK (default_currency_code IN (\'NGN\', \'GHS\', \'KES\', \'ZAR\', \'USD\', \'GBP\', \'EUR\'))',
        'CHECK (theme_mode IN (\'system\', \'light\', \'dark\'))',
      ];
}
