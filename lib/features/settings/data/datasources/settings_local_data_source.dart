import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/settings_dao.dart';

abstract class SettingsLocalDataSource {
  Stream<AppSettingsRow?> watchSettings();
  Future<AppSettingsRow?> getSettings();
  Future<void> insertSettings(AppSettingsTableCompanion companion);
  Future<void> updateDefaultCurrency(String currencyCode);
  Future<void> updateThemeMode(String themeMode);
  Future<ShoppingListRow> completeOnboarding({
    required String currencyCode,
    required String listId,
    required String listName,
    required int nowEpochMs,
  });
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SettingsDao _settingsDao;

  SettingsLocalDataSourceImpl(this._settingsDao);

  @override
  Stream<AppSettingsRow?> watchSettings() => _settingsDao.watchSettings();

  @override
  Future<AppSettingsRow?> getSettings() => _settingsDao.getSettings();

  @override
  Future<void> insertSettings(AppSettingsTableCompanion companion) =>
      _settingsDao.insertSettings(companion);

  @override
  Future<void> updateDefaultCurrency(String currencyCode) =>
      _settingsDao.updateDefaultCurrency(currencyCode);

  @override
  Future<void> updateThemeMode(String themeMode) =>
      _settingsDao.updateThemeMode(themeMode);

  @override
  Future<ShoppingListRow> completeOnboarding({
    required String currencyCode,
    required String listId,
    required String listName,
    required int nowEpochMs,
  }) =>
      _settingsDao.completeOnboarding(
        currencyCode: currencyCode,
        listId: listId,
        listName: listName,
        nowEpochMs: nowEpochMs,
      );
}
