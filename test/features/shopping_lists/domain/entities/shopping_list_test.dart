import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

void main() {
  group('ShoppingList entity', () {
    test('FR-001 supports value equality and copyWith', () {
      final now = DateTime.utc(2026, 10, 14);
      final list1 = ShoppingList(
        id: 'list-1',
        name: 'Weekly groceries',
        currency: CurrencyCode.ngn,
        createdAt: now,
        updatedAt: now,
      );

      final list2 = ShoppingList(
        id: 'list-1',
        name: 'Weekly groceries',
        currency: CurrencyCode.ngn,
        createdAt: now,
        updatedAt: now,
      );

      expect(list1, equals(list2));

      final updated = list1.copyWith(
        id: 'list-2',
        name: 'Updated groceries',
        currency: CurrencyCode.eur,
        createdAt: now.add(const Duration(days: 1)),
        updatedAt: now.add(const Duration(days: 2)),
      );
      expect(updated.id, 'list-2');
      expect(updated.name, 'Updated groceries');
      expect(updated.currency, CurrencyCode.eur);
      expect(updated.createdAt, now.add(const Duration(days: 1)));
      expect(updated.updatedAt, now.add(const Duration(days: 2)));

      expect(list1.copyWith(), equals(list1));
      expect(list1.props, ['list-1', 'Weekly groceries', CurrencyCode.ngn, now, now]);
    });
  });

  group('ListSummary entity', () {
    test('FR-060 supports value equality and props', () {
      final now = DateTime.utc(2026, 10, 14);
      final list = ShoppingList(
        id: 'list-1',
        name: 'Weekly groceries',
        currency: CurrencyCode.usd,
        createdAt: now,
        updatedAt: now,
      );

      final summary1 = ListSummary(
        list: list,
        itemCount: 5,
        total: const Money(125050),
      );

      final summary2 = ListSummary(
        list: list,
        itemCount: 5,
        total: const Money(125050),
      );

      expect(summary1, equals(summary2));
      expect(summary1.props, [list, 5, const Money(125050)]);
    });
  });
}
