import 'dart:io';
import 'dart:math' as math;
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/error/failures.dart';

void main() {
  setUpAll(() {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('AppDatabase tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('FR-080 CRUD operations on in-memory database', () async {
      // 1. Create list
      const listId = 'list-1';
      final now = DateTime.utc(2026, 10, 14).millisecondsSinceEpoch;
      await db.listsDao.insertList(
        ShoppingListsTableCompanion.insert(
          id: listId,
          name: 'Weekend Groceries',
          currencyCode: 'USD',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final fetchedList = await db.listsDao.getList(listId);
      expect(fetchedList, isNotNull);
      expect(fetchedList!.name, 'Weekend Groceries');
      expect(fetchedList.currencyCode, 'USD');

      // 2. Add items
      const itemId = 'item-1';
      await db.itemsDao.insertItem(
        ShoppingItemsTableCompanion.insert(
          id: itemId,
          listId: listId,
          name: 'Apples',
          quantityMilli: 2500,
          unit: const drift.Value('kg'),
          unitPriceMinor: 350,
          isBought: const drift.Value(false),
          createdAt: now,
          updatedAt: now,
        ),
        now,
      );

      final item = await db.itemsDao.getItem(itemId);
      expect(item, isNotNull);
      expect(item!.name, 'Apples');
      expect(item.quantityMilli, 2500);
      expect(item.unit, 'kg');
      expect(item.unitPriceMinor, 350);
      expect(item.isBought, isFalse);

      // 3. Update item
      final updatedNow = now + 1000;
      final updatedItem = await db.itemsDao.updateItem(
        const ShoppingItemsTableCompanion(
          id: drift.Value(itemId),
          name: drift.Value('Green Apples'),
          quantityMilli: drift.Value(3000),
          unit: drift.Value('kg'),
          unitPriceMinor: drift.Value(400),
        ),
        updatedNow,
      );
      expect(updatedItem, isNotNull);
      expect(updatedItem!.name, 'Green Apples');
      expect(updatedItem.quantityMilli, 3000);
      expect(updatedItem.unitPriceMinor, 400);

      // 4. Toggle bought
      await db.itemsDao.setBought(itemId, true, updatedNow + 1000);
      final boughtItem = await db.itemsDao.getItem(itemId);
      expect(boughtItem!.isBought, isTrue);

      // 5. Delete item
      final deleted = await db.itemsDao.deleteItem(itemId, updatedNow + 2000);
      expect(deleted, isNotNull);
      expect(deleted!.id, itemId);
      final remaining = await db.itemsDao.getItem(itemId);
      expect(remaining, isNull);

      // 6. Restore item
      await db.itemsDao.restoreItem(deleted, updatedNow + 3000);
      final restored = await db.itemsDao.getItem(itemId);
      expect(restored, isNotNull);
      expect(restored!.name, 'Green Apples');
    });

    test('FR-080 Cascade delete deletes child items when list is deleted', () async {
      const listId = 'list-cascade';
      final now = DateTime.utc(2026, 10, 14).millisecondsSinceEpoch;
      await db.listsDao.insertList(
        ShoppingListsTableCompanion.insert(
          id: listId,
          name: 'To Delete',
          currencyCode: 'EUR',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.itemsDao.insertItem(
        ShoppingItemsTableCompanion.insert(
          id: 'item-cascade-1',
          listId: listId,
          name: 'Item 1',
          quantityMilli: 1000,
          unitPriceMinor: 100,
          createdAt: now,
          updatedAt: now,
        ),
        now,
      );

      expect(await db.itemsDao.itemCount(listId), 1);

      await db.listsDao.deleteList(listId);

      expect(await db.listsDao.getList(listId), isNull);
      expect(await db.itemsDao.getItem('item-cascade-1'), isNull);
      expect(await db.itemsDao.itemCount(listId), 0);
    });

    test('FR-080 Touch rule updates parent list updated_at on all item operations', () async {
      const listId = 'list-touch';
      final t0 = 1000000;
      await db.listsDao.insertList(
        ShoppingListsTableCompanion.insert(
          id: listId,
          name: 'Touch test',
          currencyCode: 'USD',
          createdAt: t0,
          updatedAt: t0,
        ),
      );

      // Add item touches list
      await db.itemsDao.insertItem(
        ShoppingItemsTableCompanion.insert(
          id: 'item-touch',
          listId: listId,
          name: 'Item',
          quantityMilli: 1000,
          unitPriceMinor: 100,
          createdAt: t0,
          updatedAt: t0,
        ),
        t0 + 10,
      );
      var list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 10);

      // Update item touches list
      await db.itemsDao.updateItem(
        const ShoppingItemsTableCompanion(
          id: drift.Value('item-touch'),
          name: drift.Value('Item updated'),
          quantityMilli: drift.Value(1000),
          unitPriceMinor: drift.Value(100),
        ),
        t0 + 20,
      );
      list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 20);

      // Set bought touches list
      await db.itemsDao.setBought('item-touch', true, t0 + 30);
      list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 30);

      // Delete item touches list
      final deleted = await db.itemsDao.deleteItem('item-touch', t0 + 40);
      list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 40);

      // Restore item touches list
      await db.itemsDao.restoreItem(deleted!, t0 + 50);
      list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 50);

      // Rename list touches list
      await db.listsDao.renameList(listId, 'Renamed', t0 + 60);
      list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 60);

      // Set currency touches list
      await db.listsDao.setCurrency(listId, 'EUR', t0 + 70);
      list = await db.listsDao.getList(listId);
      expect(list!.updatedAt, t0 + 70);
    });

    test('NFR-006 Transaction rollbacks leave no partial rows on thrown error', () async {
      const listId = 'list-rollback';
      final now = DateTime.utc(2026, 10, 14).millisecondsSinceEpoch;
      await db.listsDao.insertList(
        ShoppingListsTableCompanion.insert(
          id: listId,
          name: 'Rollback List',
          currencyCode: 'USD',
          createdAt: now,
          updatedAt: now,
        ),
      );

      try {
        await db.transaction(() async {
          await db.itemsDao.insertItem(
            ShoppingItemsTableCompanion.insert(
              id: 'item-rollback-1',
              listId: listId,
              name: 'Valid Item',
              quantityMilli: 1000,
              unitPriceMinor: 100,
              createdAt: now,
              updatedAt: now,
            ),
            now,
          );

          // Force an exception inside the transaction
          throw Exception('Simulated crash during write');
        });
      } catch (_) {
        // Expected
      }

      // Check that the item was rolled back
      final item = await db.itemsDao.getItem('item-rollback-1');
      expect(item, isNull);
    });

    test('FR-063 SQL parity test matches Dart line total and sum on 1,000 random rows', () async {
      const listId = 'list-parity';
      final now = DateTime.utc(2026, 10, 14).millisecondsSinceEpoch;
      await db.listsDao.insertList(
        ShoppingListsTableCompanion.insert(
          id: listId,
          name: 'Parity Test',
          currencyCode: 'NGN',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final random = math.Random(12345);
      var dartTotal = 0;

      await db.batch((batch) {
        for (var i = 0; i < 1000; i++) {
          // quantityMilli: 1 to 9,999,999
          final qty = random.nextInt(AppLimits.maxQuantityMilli) + 1;
          // unitPriceMinor: 0 to 9,999,999,999 (use 32-bit bound here for random int generator)
          final price = random.nextInt(10000000);

          final lineTotal = (qty * price + 500) ~/ 1000;
          dartTotal += lineTotal;

          batch.insert(
            db.shoppingItemsTable,
            ShoppingItemsTableCompanion.insert(
              id: 'parity-$i',
              listId: listId,
              name: 'Item $i',
              quantityMilli: qty,
              unitPriceMinor: price,
              createdAt: now + i,
              updatedAt: now + i,
            ),
          );
        }
      });

      final summaries = await db.listsDao.watchSummaries().first;
      final paritySummary = summaries.firstWhere((s) => s.list.id == listId);

      expect(paritySummary.itemCount, 1000);
      expect(paritySummary.totalMinor, dartTotal);
    });

    test('FR-080 PRAGMA foreign_keys is ON and synchronous is FULL', () async {
      final fkRes = await db.customSelect('PRAGMA foreign_keys;').getSingle();
      expect(fkRes.read<int>('foreign_keys'), 1);

      final syncRes = await db.customSelect('PRAGMA synchronous;').getSingle();
      // FULL is 2
      expect(syncRes.read<int>('synchronous'), 2);
    });

    test('FR-080 File database PRAGMA journal_mode is delete', () async {
      final tempDir = Directory.systemTemp.createTempSync('ml_db_test_');
      final dbFile = File('${tempDir.path}/market_list.sqlite');

      final fileDb = AppDatabase(NativeDatabase(dbFile));
      try {
        final journalRes = await fileDb.customSelect('PRAGMA journal_mode;').getSingle();
        final mode = journalRes.read<String>('journal_mode').toLowerCase();
        expect(mode, 'delete');
      } finally {
        await fileDb.close();
        tempDir.deleteSync(recursive: true);
      }
    });

    test('FR-082 Newer-schema database throws SchemaTooNewException and remains unchanged', () async {
      final tempDir = Directory.systemTemp.createTempSync('ml_schema_test_');
      final dbFile = File('${tempDir.path}/market_list.sqlite');

      // Create a database with user_version = 2
      final rawDb = NativeDatabase(dbFile);
      final seedDb = AppDatabase(rawDb);
      // Wait for creation
      await seedDb.customStatement('PRAGMA user_version = 2;');
      await seedDb.close();

      // Now open with AppDatabase (schemaVersion = 1)
      final openingDb = AppDatabase(NativeDatabase(dbFile));
      await expectLater(
        openingDb.customSelect('SELECT 1;').get(),
        throwsA(isA<SchemaTooNewException>()),
      );
      try {
        await openingDb.close();
      } catch (_) {}

      // Verify user_version is still 2 and file was not modified/corrupted
      final checkDb = _TestV2Database(NativeDatabase(dbFile));
      final versionRes = await checkDb.customSelect('PRAGMA user_version;').getSingle();
      expect(versionRes.read<int>('user_version'), 2);
      await checkDb.close();

      tempDir.deleteSync(recursive: true);
    });

    test('FR-082 mapDatabaseException maps exceptions correctly', () {
      // 1. SchemaTooNewException -> SchemaTooNewFailure
      expect(
        mapDatabaseException(const SchemaTooNewException(storedVersion: 2, appVersion: 1)),
        const SchemaTooNewFailure(),
      );

      // 2. SqliteException with resultCode 13 (SQLITE_FULL) -> StorageFullFailure
      final sqliteFull = SqliteException(13, 'database or disk is full');
      expect(mapDatabaseException(sqliteFull), const StorageFullFailure());

      // 3. DriftWrappedException with cause SQLITE_FULL -> StorageFullFailure
      final wrappedFull = drift.DriftWrappedException(
        message: 'Drift wrapped',
        cause: sqliteFull,
      );
      expect(mapDatabaseException(wrappedFull), const StorageFullFailure());

      // 4. CouldNotRollBackException with cause SQLITE_FULL -> StorageFullFailure
      final rollbackFull = drift.CouldNotRollBackException(
        sqliteFull,
        StackTrace.current,
        Exception('rollback failed'),
      );
      expect(mapDatabaseException(rollbackFull), const StorageFullFailure());

      // 5. Generic SqliteException -> DatabaseFailure
      final sqliteGeneric = SqliteException(1, 'SQL error');
      expect(
        mapDatabaseException(sqliteGeneric),
        const DatabaseFailure('SQL error'),
      );

      // 6. Generic exception -> UnexpectedFailure
      expect(
        mapDatabaseException(Exception('generic error')),
        UnexpectedFailure(Exception('generic error').toString()),
      );
    });
  });
}

class _TestV2Database extends AppDatabase {
  _TestV2Database(super.executor);

  @override
  int get schemaVersion => 2;
}

