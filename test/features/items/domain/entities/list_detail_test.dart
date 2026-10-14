import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/item_validation_errors.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

void main() {
  group('ListDetail entity', () {
    final now = DateTime.utc(2026, 10, 14);
    final list = ShoppingList(
      id: 'l1',
      name: 'Sunday market',
      currency: CurrencyCode.ngn,
      createdAt: now,
      updatedAt: now,
    );

    test('FR-060 getters total, boughtCount, itemCount calculate correctly', () {
      final items = [
        ShoppingItem(
          id: '1',
          listId: 'l1',
          name: 'Tomatoes',
          quantity: const Quantity.fromMilli(2500),
          unit: 'kg',
          unitPrice: const Money.fromMinor(150000), // line total: 375000
          isBought: true,
          createdAt: now,
          updatedAt: now,
        ),
        ShoppingItem(
          id: '2',
          listId: 'l1',
          name: 'Onions',
          quantity: const Quantity.fromMilli(3000),
          unit: 'pcs',
          unitPrice: const Money.fromMinor(20000), // line total: 60000
          isBought: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final detail = ListDetail(list: list, items: items);

      expect(detail.itemCount, 2);
      expect(detail.boughtCount, 1);
      expect(detail.total, const Money.fromMinor(435000));
    });

    test('FR-060 empty items produces 0 total, 0 itemCount, 0 boughtCount', () {
      final detail = ListDetail(list: list, items: const []);

      expect(detail.itemCount, 0);
      expect(detail.boughtCount, 0);
      expect(detail.total, Money.zero);
    });
  });

  group('ItemDraft & ItemValidationErrors', () {
    test('ItemDraft supports equality and copyWith', () {
      final draft1 = const ItemDraft(
        name: 'Tomatoes',
        quantity: Quantity.fromMilli(2000),
        unit: 'kg',
        unitPrice: Money.fromMinor(1000),
      );
      final draft2 = const ItemDraft(
        name: 'Tomatoes',
        quantity: Quantity.fromMilli(2000),
        unit: 'kg',
        unitPrice: Money.fromMinor(1000),
      );
      expect(draft1, equals(draft2));

      final updated = draft1.copyWith(name: 'Roma Tomatoes');
      expect(updated.name, 'Roma Tomatoes');
      expect(updated.unit, 'kg');
      expect(draft1.copyWith(), equals(draft1));
      expect(draft1.props, ['Tomatoes', const Quantity.fromMilli(2000), 'kg', const Money.fromMinor(1000)]);
    });

    test('ItemValidationErrors tracks hasErrors accurately', () {
      const noErrors = ItemValidationErrors();
      expect(noErrors.hasErrors, isFalse);

      const withNameError = ItemValidationErrors(nameError: 'Enter an item name.');
      expect(withNameError.hasErrors, isTrue);
      expect(withNameError.props, ['Enter an item name.', null, null, null]);
    });
  });
}
