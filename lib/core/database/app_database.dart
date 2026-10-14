import 'package:drift/drift.dart';
import 'package:market_list/core/database/connection/native.dart'
    if (dart.library.html) 'package:market_list/core/database/connection/unsupported.dart';
import 'package:market_list/core/database/daos/items_dao.dart';
import 'package:market_list/core/database/daos/lists_dao.dart';
import 'package:market_list/core/database/daos/settings_dao.dart';
import 'package:market_list/core/database/tables/app_settings_table.dart';
import 'package:market_list/core/database/tables/shopping_items_table.dart';
import 'package:market_list/core/database/tables/shopping_lists_table.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:drift/native.dart' show SqliteException;

part 'app_database.g.dart';

class SchemaTooNewException implements Exception {
  final int storedVersion;
  final int appVersion;

  const SchemaTooNewException({
    required this.storedVersion,
    required this.appVersion,
  });

  @override
  String toString() =>
      'SchemaTooNewException: storedVersion $storedVersion > appVersion $appVersion';
}

Failure mapDatabaseException(Object error) {
  if (error is SchemaTooNewException) {
    return const SchemaTooNewFailure();
  }
  if (error is DriftWrappedException) {
    final cause = error.cause;
    if (cause != null) {
      return mapDatabaseException(cause);
    }
  }
  if (error is CouldNotRollBackException) {
    return mapDatabaseException(error.cause);
  }
  if (error is SqliteException) {
    if (error.resultCode == 13 /* SQLITE_FULL */) {
      return const StorageFullFailure();
    }
    return DatabaseFailure(error.message);
  }
  return UnexpectedFailure(error.toString());
}

@DriftDatabase(
  tables: [ShoppingListsTable, ShoppingItemsTable, AppSettingsTable],
  daos: [ListsDao, ItemsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? connectDatabase());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from > to) {
            throw SchemaTooNewException(storedVersion: from, appVersion: to);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          if (details.versionBefore != null &&
              details.versionBefore! > schemaVersion) {
            throw SchemaTooNewException(
              storedVersion: details.versionBefore!,
              appVersion: schemaVersion,
            );
          }
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA synchronous = FULL;');
          await customStatement('PRAGMA journal_mode = DELETE;');
        },
      );
}
