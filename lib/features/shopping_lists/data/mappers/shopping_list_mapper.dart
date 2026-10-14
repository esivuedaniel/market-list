import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/lists_dao.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class ShoppingListMapper {
  const ShoppingListMapper();

  ShoppingList toEntity(ShoppingListRow row) {
    return ShoppingList(
      id: row.id,
      name: row.name,
      currency: CurrencyCode.fromCode(row.currencyCode),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
    );
  }

  ListSummary toSummaryEntity(ListSummaryRow row) {
    return ListSummary(
      list: toEntity(row.list),
      itemCount: row.itemCount,
      total: Money.fromMinor(row.totalMinor),
    );
  }

  ShoppingListsTableCompanion toCompanion({
    required String id,
    required String name,
    required CurrencyCode currency,
    required int createdAt,
    required int updatedAt,
  }) {
    return ShoppingListsTableCompanion.insert(
      id: id,
      name: name,
      currencyCode: currency.code,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
