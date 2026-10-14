import 'package:drift/drift.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/tables/shopping_items_table.dart';
import 'package:market_list/core/database/tables/shopping_lists_table.dart';

part 'items_dao.g.dart';

class ListDetailRow {
  final ShoppingListRow list;
  final List<ShoppingItemRow> items;

  const ListDetailRow({
    required this.list,
    required this.items,
  });
}

@DriftAccessor(tables: [ShoppingListsTable, ShoppingItemsTable])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Stream<ListDetailRow?> watchListWithItems(String listId) {
    final query = customSelect(
      'SELECT '
      'l.id AS l_id, l.name AS l_name, l.currency_code AS l_currency_code, '
      'l.created_at AS l_created_at, l.updated_at AS l_updated_at, '
      'i.id AS i_id, i.list_id AS i_list_id, i.name AS i_name, '
      'i.quantity_milli AS i_quantity_milli, i.unit AS i_unit, '
      'i.unit_price_minor AS i_unit_price_minor, i.is_bought AS i_is_bought, '
      'i.created_at AS i_created_at, i.updated_at AS i_updated_at '
      'FROM shopping_lists l '
      'LEFT JOIN shopping_items i ON i.list_id = l.id '
      'WHERE l.id = ? '
      'ORDER BY i.created_at ASC, i.id ASC',
      variables: [Variable.withString(listId)],
      readsFrom: {shoppingListsTable, shoppingItemsTable},
    );

    return query.watch().map(_mapListDetailRows);
  }

  Future<ListDetailRow?> getListDetail(String listId) async {
    final query = customSelect(
      'SELECT '
      'l.id AS l_id, l.name AS l_name, l.currency_code AS l_currency_code, '
      'l.created_at AS l_created_at, l.updated_at AS l_updated_at, '
      'i.id AS i_id, i.list_id AS i_list_id, i.name AS i_name, '
      'i.quantity_milli AS i_quantity_milli, i.unit AS i_unit, '
      'i.unit_price_minor AS i_unit_price_minor, i.is_bought AS i_is_bought, '
      'i.created_at AS i_created_at, i.updated_at AS i_updated_at '
      'FROM shopping_lists l '
      'LEFT JOIN shopping_items i ON i.list_id = l.id '
      'WHERE l.id = ? '
      'ORDER BY i.created_at ASC, i.id ASC',
      variables: [Variable.withString(listId)],
      readsFrom: {shoppingListsTable, shoppingItemsTable},
    );

    final rows = await query.get();
    return _mapListDetailRows(rows);
  }

  ListDetailRow? _mapListDetailRows(List<QueryRow> rows) {
    if (rows.isEmpty) return null;

    final first = rows.first;
    final list = ShoppingListRow(
      id: first.read<String>('l_id'),
      name: first.read<String>('l_name'),
      currencyCode: first.read<String>('l_currency_code'),
      createdAt: first.read<int>('l_created_at'),
      updatedAt: first.read<int>('l_updated_at'),
    );

    final items = <ShoppingItemRow>[];
    for (final row in rows) {
      final itemId = row.readNullable<String>('i_id');
      if (itemId != null) {
        items.add(ShoppingItemRow(
          id: itemId,
          listId: row.read<String>('i_list_id'),
          name: row.read<String>('i_name'),
          quantityMilli: row.read<int>('i_quantity_milli'),
          unit: row.readNullable<String>('i_unit'),
          unitPriceMinor: row.read<int>('i_unit_price_minor'),
          isBought: row.read<bool>('i_is_bought'),
          createdAt: row.read<int>('i_created_at'),
          updatedAt: row.read<int>('i_updated_at'),
        ));
      }
    }

    return ListDetailRow(list: list, items: items);
  }

  Future<ShoppingItemRow?> getItem(String id) {
    return (select(shoppingItemsTable)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ShoppingItemRow> insertItem(
    ShoppingItemsTableCompanion companion,
    int nowEpochMs,
  ) {
    return transaction(() async {
      await into(shoppingItemsTable).insert(companion);
      await (update(shoppingListsTable)
            ..where((tbl) => tbl.id.equals(companion.listId.value)))
          .write(ShoppingListsTableCompanion(updatedAt: Value(nowEpochMs)));

      return (select(shoppingItemsTable)
            ..where((tbl) => tbl.id.equals(companion.id.value)))
          .getSingle();
    });
  }

  Future<ShoppingItemRow?> updateItem(
    ShoppingItemsTableCompanion companion,
    int nowEpochMs,
  ) {
    return transaction(() async {
      final rowsUpdated = await (update(shoppingItemsTable)
            ..where((tbl) => tbl.id.equals(companion.id.value)))
          .write(companion);

      if (rowsUpdated == 0) return null;

      final item = await (select(shoppingItemsTable)
            ..where((tbl) => tbl.id.equals(companion.id.value)))
          .getSingle();

      await (update(shoppingListsTable)
            ..where((tbl) => tbl.id.equals(item.listId)))
          .write(ShoppingListsTableCompanion(updatedAt: Value(nowEpochMs)));

      return item;
    });
  }

  Future<ShoppingItemRow?> deleteItem(String id, int nowEpochMs) {
    return transaction(() async {
      final item = await (select(shoppingItemsTable)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (item == null) return null;

      await (delete(shoppingItemsTable)..where((tbl) => tbl.id.equals(id))).go();

      await (update(shoppingListsTable)
            ..where((tbl) => tbl.id.equals(item.listId)))
          .write(ShoppingListsTableCompanion(updatedAt: Value(nowEpochMs)));

      return item;
    });
  }

  Future<void> restoreItem(ShoppingItemRow item, int nowEpochMs) {
    return transaction(() async {
      await into(shoppingItemsTable).insert(
        ShoppingItemsTableCompanion.insert(
          id: item.id,
          listId: item.listId,
          name: item.name,
          quantityMilli: item.quantityMilli,
          unit: Value(item.unit),
          unitPriceMinor: item.unitPriceMinor,
          isBought: Value(item.isBought),
          createdAt: item.createdAt,
          updatedAt: nowEpochMs,
        ),
      );

      await (update(shoppingListsTable)
            ..where((tbl) => tbl.id.equals(item.listId)))
          .write(ShoppingListsTableCompanion(updatedAt: Value(nowEpochMs)));
    });
  }

  Future<int> setBought(String id, bool isBought, int nowEpochMs) {
    return transaction(() async {
      final item = await (select(shoppingItemsTable)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      if (item == null) return 0;

      await (update(shoppingItemsTable)..where((tbl) => tbl.id.equals(id)))
          .write(ShoppingItemsTableCompanion(
        isBought: Value(isBought),
        updatedAt: Value(nowEpochMs),
      ));

      await (update(shoppingListsTable)
            ..where((tbl) => tbl.id.equals(item.listId)))
          .write(ShoppingListsTableCompanion(updatedAt: Value(nowEpochMs)));

      return 1;
    });
  }

  Future<int> itemCount(String listId) async {
    final countExp = shoppingItemsTable.id.count();
    final query = selectOnly(shoppingItemsTable)
      ..addColumns([countExp])
      ..where(shoppingItemsTable.listId.equals(listId));
    return (await query.map((row) => row.read(countExp)).getSingle()) ?? 0;
  }

  Future<bool> hasDuplicateName(
    String listId,
    String normalizedName,
    String? excludeId,
  ) async {
    var query = select(shoppingItemsTable)
      ..where((tbl) =>
          tbl.listId.equals(listId) &
          tbl.name.collate(Collate.noCase).equals(normalizedName));
    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.equals(excludeId).not());
    }
    final found = await query.get();
    return found.isNotEmpty;
  }
}
