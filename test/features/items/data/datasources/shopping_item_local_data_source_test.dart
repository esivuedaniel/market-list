import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/features/items/data/datasources/shopping_item_local_data_source.dart';

void main() {
  late AppDatabase db;
  late ShoppingItemLocalDataSource dataSource;

  const listId = 'list-items-ds';
  const now = 1000;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = ShoppingItemLocalDataSourceImpl(db.itemsDao);

    // Create a parent list
    await db.listsDao.insertList(
      ShoppingListsTableCompanion.insert(
        id: listId,
        name: 'Grocery List',
        currencyCode: 'USD',
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ShoppingItemLocalDataSourceImpl', () {
    test('FR-080 CRUD operations delegate to itemsDao', () async {
      const itemId = 'item-ds-1';

      // 1. Insert item
      final inserted = await dataSource.insertItem(
        ShoppingItemsTableCompanion.insert(
          id: itemId,
          listId: listId,
          name: 'Apples',
          quantityMilli: 1500,
          unitPriceMinor: 200,
          createdAt: now,
          updatedAt: now,
        ),
        now,
      );
      expect(inserted.id, itemId);
      expect(inserted.name, 'Apples');

      // 2. Get item
      final fetched = await dataSource.getItem(itemId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Apples');

      // 3. Count
      expect(await dataSource.itemCount(listId), 1);

      // 4. Duplicate name check
      expect(await dataSource.hasDuplicateName(listId, 'Apples', null), isTrue);
      expect(await dataSource.hasDuplicateName(listId, 'Apples', itemId), isFalse);
      expect(await dataSource.hasDuplicateName(listId, 'Bananas', null), isFalse);

      // 5. Update item
      final updated = await dataSource.updateItem(
        const ShoppingItemsTableCompanion(
          id: Value(itemId),
          name: Value('Green Apples'),
          quantityMilli: Value(2000),
          unitPriceMinor: Value(250),
        ),
        now + 100,
      );
      expect(updated, isNotNull);
      expect(updated!.name, 'Green Apples');

      // 6. Set bought
      await dataSource.setBought(itemId, true, now + 200);
      final boughtItem = await dataSource.getItem(itemId);
      expect(boughtItem!.isBought, isTrue);

      // 7. Watch list with items
      final listDetail = await dataSource.watchListWithItems(listId).first;
      expect(listDetail, isNotNull);
      expect(listDetail!.items.length, 1);

      // 8. Get list detail
      final detail = await dataSource.getListDetail(listId);
      expect(detail, isNotNull);
      expect(detail!.items.first.name, 'Green Apples');

      // 9. Delete item
      final deleted = await dataSource.deleteItem(itemId, now + 300);
      expect(deleted, isNotNull);
      expect(await dataSource.getItem(itemId), isNull);
      expect(await dataSource.itemCount(listId), 0);

      // 10. Restore item
      await dataSource.restoreItem(deleted!, now + 400);
      expect(await dataSource.getItem(itemId), isNotNull);
      expect(await dataSource.itemCount(listId), 1);
    });
  });
}
