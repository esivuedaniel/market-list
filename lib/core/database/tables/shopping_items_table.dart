import 'package:drift/drift.dart';
import 'package:market_list/core/database/tables/shopping_lists_table.dart';

@DataClassName('ShoppingItemRow')
@TableIndex(name: 'idx_items_list_created', columns: {#listId, #createdAt})
class ShoppingItemsTable extends Table {
  @override
  String get tableName => 'shopping_items';

  TextColumn get id => text()();
  TextColumn get listId => text().named('list_id').references(
        ShoppingListsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get name => text()();
  IntColumn get quantityMilli => integer().named('quantity_milli')();
  TextColumn get unit => text().nullable()();
  IntColumn get unitPriceMinor => integer().named('unit_price_minor')();
  BoolColumn get isBought =>
      boolean().named('is_bought').withDefault(const Constant(false))();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (length(name) >= 1 AND length(name) <= 80)',
        'CHECK (quantity_milli >= 1 AND quantity_milli <= 9999999)',
        'CHECK (unit IS NULL OR (length(unit) >= 1 AND length(unit) <= 20))',
        'CHECK (unit_price_minor >= 0 AND unit_price_minor <= 9999999999)',
      ];
}
