import 'package:drift/drift.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/tables/app_settings_table.dart';
import 'package:market_list/core/database/tables/shopping_lists_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable, ShoppingListsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<AppSettingsRow?> watchSettings() {
    return (select(appSettingsTable)..where((tbl) => tbl.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<AppSettingsRow?> getSettings() {
    return (select(appSettingsTable)..where((tbl) => tbl.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> insertSettings(AppSettingsTableCompanion companion) {
    return into(appSettingsTable).insert(companion);
  }

  Future<void> updateDefaultCurrency(String currencyCode) async {
    await (update(appSettingsTable)..where((tbl) => tbl.id.equals(1))).write(
      AppSettingsTableCompanion(
        defaultCurrencyCode: Value(currencyCode),
      ),
    );
  }

  Future<void> updateThemeMode(String themeMode) async {
    await (update(appSettingsTable)..where((tbl) => tbl.id.equals(1))).write(
      AppSettingsTableCompanion(
        themeMode: Value(themeMode),
      ),
    );
  }

  Future<ShoppingListRow> completeOnboarding({
    required String currencyCode,
    required String listId,
    required String listName,
    required int nowEpochMs,
  }) {
    return transaction(() async {
      final current = await getSettings();
      if (current == null) {
        await into(appSettingsTable).insert(AppSettingsTableCompanion.insert(
          id: const Value(1),
          defaultCurrencyCode: currencyCode,
          themeMode: const Value('system'),
          onboardingDone: const Value(true),
        ));
      } else {
        await (update(appSettingsTable)..where((tbl) => tbl.id.equals(1))).write(
          AppSettingsTableCompanion(
            defaultCurrencyCode: Value(currencyCode),
            onboardingDone: const Value(true),
          ),
        );
      }

      final listCompanion = ShoppingListsTableCompanion.insert(
        id: listId,
        name: listName,
        currencyCode: currencyCode,
        createdAt: nowEpochMs,
        updatedAt: nowEpochMs,
      );
      await into(shoppingListsTable).insert(listCompanion);

      return ShoppingListRow(
        id: listId,
        name: listName,
        currencyCode: currencyCode,
        createdAt: nowEpochMs,
        updatedAt: nowEpochMs,
      );
    });
  }
}
