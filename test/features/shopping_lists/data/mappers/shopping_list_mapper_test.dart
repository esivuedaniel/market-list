import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/lists_dao.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/shopping_lists/data/mappers/shopping_list_mapper.dart';

void main() {
  const mapper = ShoppingListMapper();

  group('ShoppingListMapper', () {
    test('FR-080 toEntity maps row to ShoppingList', () {
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final row = ShoppingListRow(
        id: 'list-123',
        name: 'Weekly Groceries',
        currencyCode: 'USD',
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      final entity = mapper.toEntity(row);

      expect(entity.id, 'list-123');
      expect(entity.name, 'Weekly Groceries');
      expect(entity.currency, CurrencyCode.usd);
      expect(entity.createdAt, now);
      expect(entity.updatedAt, now);
    });

    test('FR-080 toSummaryEntity maps row to ListSummary', () {
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final listRow = ShoppingListRow(
        id: 'list-123',
        name: 'Weekly Groceries',
        currencyCode: 'EUR',
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );
      final summaryRow = ListSummaryRow(
        list: listRow,
        itemCount: 5,
        totalMinor: 1550,
      );

      final summary = mapper.toSummaryEntity(summaryRow);

      expect(summary.list.id, 'list-123');
      expect(summary.list.currency, CurrencyCode.eur);
      expect(summary.itemCount, 5);
      expect(summary.total, const Money(1550));
    });

    test('FR-080 toCompanion creates ShoppingListsTableCompanion', () {
      final companion = mapper.toCompanion(
        id: 'list-new',
        name: 'Party Supplies',
        currency: CurrencyCode.gbp,
        createdAt: 1000,
        updatedAt: 1000,
      );

      expect(companion.id.value, 'list-new');
      expect(companion.name.value, 'Party Supplies');
      expect(companion.currencyCode.value, 'GBP');
      expect(companion.createdAt.value, 1000);
      expect(companion.updatedAt.value, 1000);
    });
  });
}
