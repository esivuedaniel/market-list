import 'package:drift/drift.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/tables/shopping_items_table.dart';
import 'package:market_list/core/database/tables/shopping_lists_table.dart';

part 'lists_dao.g.dart';

class ListSummaryRow {
  final ShoppingListRow list;
  final int itemCount;
  final int totalMinor;

  const ListSummaryRow({
    required this.list,
    required this.itemCount,
    required this.totalMinor,
  });
}

@DriftAccessor(tables: [ShoppingListsTable, ShoppingItemsTable])
class ListsDao extends DatabaseAccessor<AppDatabase> with _$ListsDaoMixin {
  ListsDao(super.db);

  Stream<List<ListSummaryRow>> watchSummaries() {
    final query = customSelect(
      'SELECT '
      'l.id, l.name, l.currency_code, l.created_at, l.updated_at, '
      'COUNT(i.id) AS item_count, '
      'COALESCE(SUM((i.quantity_milli * i.unit_price_minor + 500) / 1000), 0) AS total_minor '
      'FROM shopping_lists l '
      'LEFT JOIN shopping_items i ON i.list_id = l.id '
      'GROUP BY l.id '
      'ORDER BY l.updated_at DESC',
      readsFrom: {shoppingListsTable, shoppingItemsTable},
    );

    return query.watch().map((rows) {
      return rows.map((row) {
        final list = ShoppingListRow(
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          currencyCode: row.read<String>('currency_code'),
          createdAt: row.read<int>('created_at'),
          updatedAt: row.read<int>('updated_at'),
        );
        return ListSummaryRow(
          list: list,
          itemCount: row.read<int>('item_count'),
          totalMinor: row.read<int>('total_minor'),
        );
      }).toList();
    });
  }

  Future<ShoppingListRow?> getList(String id) {
    return (select(shoppingListsTable)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertList(ShoppingListsTableCompanion companion) {
    return into(shoppingListsTable).insert(companion);
  }

  Future<int> renameList(String id, String name, int updatedAt) {
    return (update(shoppingListsTable)..where((tbl) => tbl.id.equals(id))).write(
      ShoppingListsTableCompanion(
        name: Value(name),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> setCurrency(String id, String currencyCode, int updatedAt) {
    return (update(shoppingListsTable)..where((tbl) => tbl.id.equals(id))).write(
      ShoppingListsTableCompanion(
        currencyCode: Value(currencyCode),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<int> deleteList(String id) {
    return transaction(() async {
      return (delete(shoppingListsTable)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  Future<ShoppingListRow> duplicateList({
    required String sourceId,
    required String newId,
    required String newName,
    required int nowEpochMs,
    required List<String> newItemIds,
  }) {
    return transaction(() async {
      final sourceList = await getList(sourceId);
      if (sourceList == null) {
        throw StateError('Source list not found: $sourceId');
      }

      final sourceItems = await (select(shoppingItemsTable)
            ..where((tbl) => tbl.listId.equals(sourceId))
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.createdAt),
              (tbl) => OrderingTerm.asc(tbl.id),
            ]))
          .get();

      final listCompanion = ShoppingListsTableCompanion.insert(
        id: newId,
        name: newName,
        currencyCode: sourceList.currencyCode,
        createdAt: nowEpochMs,
        updatedAt: nowEpochMs,
      );
      await into(shoppingListsTable).insert(listCompanion);

      for (var i = 0; i < sourceItems.length; i++) {
        final item = sourceItems[i];
        final itemCompanion = ShoppingItemsTableCompanion.insert(
          id: newItemIds[i],
          listId: newId,
          name: item.name,
          quantityMilli: item.quantityMilli,
          unit: Value(item.unit),
          unitPriceMinor: item.unitPriceMinor,
          isBought: const Value(false),
          createdAt: nowEpochMs + i,
          updatedAt: nowEpochMs,
        );
        await into(shoppingItemsTable).insert(itemCompanion);
      }

      return ShoppingListRow(
        id: newId,
        name: newName,
        currencyCode: sourceList.currencyCode,
        createdAt: nowEpochMs,
        updatedAt: nowEpochMs,
      );
    });
  }

  Future<int> listCount() async {
    final countExp = shoppingListsTable.id.count();
    final query = selectOnly(shoppingListsTable)..addColumns([countExp]);
    return (await query.map((row) => row.read(countExp)).getSingle()) ?? 0;
  }

  Future<int> touch(String id, int updatedAt) {
    return (update(shoppingListsTable)..where((tbl) => tbl.id.equals(id))).write(
      ShoppingListsTableCompanion(
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
