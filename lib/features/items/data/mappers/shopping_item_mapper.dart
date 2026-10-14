import 'package:drift/drift.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/items_dao.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class ShoppingItemMapper {
  const ShoppingItemMapper();

  ShoppingItem toEntity(ShoppingItemRow row) {
    return ShoppingItem(
      id: row.id,
      listId: row.listId,
      name: row.name,
      quantity: Quantity(row.quantityMilli),
      unit: row.unit,
      unitPrice: Money(row.unitPriceMinor),
      isBought: row.isBought,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  ListDetail toListDetailEntity(ListDetailRow row) {
    return ListDetail(
      list: ShoppingList(
        id: row.list.id,
        name: row.list.name,
        currency: CurrencyCode.fromCode(row.list.currencyCode),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.list.createdAt, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row.list.updatedAt, isUtc: true),
      ),
      items: row.items.map(toEntity).toList(),
    );
  }

  ShoppingItemsTableCompanion toInsertCompanion({
    required String id,
    required String listId,
    required ItemDraft draft,
    required int createdAt,
    required int updatedAt,
    bool isBought = false,
  }) {
    return ShoppingItemsTableCompanion.insert(
      id: id,
      listId: listId,
      name: draft.name,
      quantityMilli: draft.quantity.milli,
      unit: Value(draft.unit),
      unitPriceMinor: draft.unitPrice.minor,
      isBought: Value(isBought),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ShoppingItemsTableCompanion toUpdateCompanion({
    required String id,
    required ItemDraft draft,
    required int updatedAt,
  }) {
    return ShoppingItemsTableCompanion(
      id: Value(id),
      name: Value(draft.name),
      quantityMilli: Value(draft.quantity.milli),
      unit: Value(draft.unit),
      unitPriceMinor: Value(draft.unitPrice.minor),
      updatedAt: Value(updatedAt),
    );
  }
}
