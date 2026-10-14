import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/features/shopping_lists/data/datasources/shopping_list_local_data_source.dart';

void main() {
  late AppDatabase db;
  late ShoppingListLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = ShoppingListLocalDataSourceImpl(db.listsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ShoppingListLocalDataSourceImpl', () {
    test('FR-080 CRUD operations delegate to listsDao', () async {
      const listId = 'list-ds-1';
      final now = 1000;

      // 1. Insert
      await dataSource.insertList(
        ShoppingListsTableCompanion.insert(
          id: listId,
          name: 'Groceries',
          currencyCode: 'USD',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 2. Get
      final item = await dataSource.getList(listId);
      expect(item, isNotNull);
      expect(item!.name, 'Groceries');

      // 3. Count
      expect(await dataSource.listCount(), 1);

      // 4. Rename
      final renamedRows = await dataSource.renameList(listId, 'Supermarket', now + 100);
      expect(renamedRows, 1);
      final renamed = await dataSource.getList(listId);
      expect(renamed!.name, 'Supermarket');

      // 5. Set currency
      final currRows = await dataSource.setCurrency(listId, 'EUR', now + 200);
      expect(currRows, 1);
      final currList = await dataSource.getList(listId);
      expect(currList!.currencyCode, 'EUR');

      // 6. Duplicate
      final duplicated = await dataSource.duplicateList(
        sourceId: listId,
        newId: 'list-ds-2',
        newName: 'Supermarket copy',
        nowEpochMs: now + 300,
        newItemIds: ['item-dup-1'],
      );
      expect(duplicated.id, 'list-ds-2');
      expect(await dataSource.listCount(), 2);

      // 7. Watch summaries
      final summaries = await dataSource.watchSummaries().first;
      expect(summaries.length, 2);

      // 8. Delete
      final deletedRows = await dataSource.deleteList(listId);
      expect(deletedRows, 1);
      expect(await dataSource.listCount(), 1);
    });
  });
}
