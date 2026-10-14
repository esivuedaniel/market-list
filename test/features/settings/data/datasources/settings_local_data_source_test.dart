import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/features/settings/data/datasources/settings_local_data_source.dart';

void main() {
  late AppDatabase db;
  late SettingsLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = SettingsLocalDataSourceImpl(db.settingsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsLocalDataSourceImpl', () {
    test('FR-080 CRUD operations delegate to settingsDao', () async {
      // 1. Initial settings is null
      expect(await dataSource.getSettings(), isNull);

      // 2. Insert settings
      await dataSource.insertSettings(
        const AppSettingsTableCompanion(
          defaultCurrencyCode: Value('USD'),
          themeMode: Value('system'),
          onboardingDone: Value(false),
        ),
      );

      final settings = await dataSource.getSettings();
      expect(settings, isNotNull);
      expect(settings!.defaultCurrencyCode, 'USD');
      expect(settings.themeMode, 'system');
      expect(settings.onboardingDone, isFalse);

      // 3. Watch settings
      final watched = await dataSource.watchSettings().first;
      expect(watched, isNotNull);
      expect(watched!.defaultCurrencyCode, 'USD');

      // 4. Update default currency
      await dataSource.updateDefaultCurrency('EUR');
      final updatedCurrency = await dataSource.getSettings();
      expect(updatedCurrency!.defaultCurrencyCode, 'EUR');

      // 5. Update theme mode
      await dataSource.updateThemeMode('dark');
      final updatedTheme = await dataSource.getSettings();
      expect(updatedTheme!.themeMode, 'dark');

      // 6. Complete onboarding creates list and sets onboardingDone = true
      final listRow = await dataSource.completeOnboarding(
        currencyCode: 'GBP',
        listId: 'list-first',
        listName: 'Market list',
        nowEpochMs: 1000,
      );
      expect(listRow.id, 'list-first');
      expect(listRow.name, 'Market list');
      expect(listRow.currencyCode, 'GBP');

      final finalSettings = await dataSource.getSettings();
      expect(finalSettings!.defaultCurrencyCode, 'GBP');
      expect(finalSettings.onboardingDone, isTrue);

      final createdList = await db.listsDao.getList('list-first');
      expect(createdList, isNotNull);
      expect(createdList!.name, 'Market list');
    });
  });
}
