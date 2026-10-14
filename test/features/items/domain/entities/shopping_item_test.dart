import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

void main() {
  group('ShoppingItem entity', () {
    final now = DateTime.utc(2026, 10, 14);

    test('FR-061 lineTotal calculates (quantityMilli * unitPriceMinor + 500) ~/ 1000 correctly', () {
      // PRD 8.5 table examples:
      // 1. 2.5 qty (2500) x 1,500.00 (150000) = 375000 (3,750.00)
      final item1 = ShoppingItem(
        id: '1',
        listId: 'l1',
        name: 'Item 1',
        quantity: const Quantity.fromMilli(2500),
        unit: 'kg',
        unitPrice: const Money.fromMinor(150000),
        isBought: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(item1.lineTotal, equals(const Money.fromMinor(375000)));

      // 2. 0.333 qty (333) x 10.00 (1000) = 333 (3.33)
      final item2 = ShoppingItem(
        id: '2',
        listId: 'l1',
        name: 'Item 2',
        quantity: const Quantity.fromMilli(333),
        unit: 'kg',
        unitPrice: const Money.fromMinor(1000),
        isBought: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(item2.lineTotal, equals(const Money.fromMinor(333)));

      // 3. 0.005 qty (5) x 1.00 (100) = 1 (0.01) (rounds up)
      final item3 = ShoppingItem(
        id: '3',
        listId: 'l1',
        name: 'Item 3',
        quantity: const Quantity.fromMilli(5),
        unit: null,
        unitPrice: const Money.fromMinor(100),
        isBought: true,
        createdAt: now,
        updatedAt: now,
      );
      expect(item3.lineTotal, equals(const Money.fromMinor(1)));

      // 4. 0.004 qty (4) x 1.00 (100) = 0 (0.00) (rounds down)
      final item4 = ShoppingItem(
        id: '4',
        listId: 'l1',
        name: 'Item 4',
        quantity: const Quantity.fromMilli(4),
        unit: null,
        unitPrice: const Money.fromMinor(100),
        isBought: false,
        createdAt: now,
        updatedAt: now,
      );
      expect(item4.lineTotal, equals(const Money.fromMinor(0)));
    });

    test('FR-010 supports value equality and copyWith', () {
      final item = ShoppingItem(
        id: '1',
        listId: 'l1',
        name: 'Milk',
        quantity: const Quantity.fromMilli(1000),
        unit: 'l',
        unitPrice: const Money.fromMinor(500),
        isBought: false,
        createdAt: now,
        updatedAt: now,
      );

      final copy = item.copyWith(
        id: '2',
        listId: 'l2',
        name: 'Whole Milk',
        quantity: const Quantity(2000),
        unit: 'carton',
        unitPrice: const Money(1200),
        isBought: true,
        createdAt: now.add(const Duration(hours: 1)),
        updatedAt: now.add(const Duration(hours: 2)),
      );
      expect(copy.id, '2');
      expect(copy.listId, 'l2');
      expect(copy.name, 'Whole Milk');
      expect(copy.quantity, const Quantity(2000));
      expect(copy.unit, 'carton');
      expect(copy.unitPrice, const Money(1200));
      expect(copy.isBought, isTrue);
      expect(copy.createdAt, now.add(const Duration(hours: 1)));
      expect(copy.updatedAt, now.add(const Duration(hours: 2)));

      expect(item.copyWith(), equals(item));
      expect(item.props, [
        '1',
        'l1',
        'Milk',
        const Quantity.fromMilli(1000),
        'l',
        const Money.fromMinor(500),
        false,
        now,
        now,
      ]);
    });
  });
}
