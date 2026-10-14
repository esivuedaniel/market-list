import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/items_dao.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';

void main() {
  const mapper = ShoppingItemMapper();

  group('ShoppingItemMapper', () {
    test('FR-080 toEntity maps ShoppingItemRow to ShoppingItem', () {
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final row = ShoppingItemRow(
        id: 'item-1',
        listId: 'list-1',
        name: 'Apples',
        quantityMilli: 2500,
        unit: 'kg',
        unitPriceMinor: 300,
        isBought: true,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      final item = mapper.toEntity(row);

      expect(item.id, 'item-1');
      expect(item.listId, 'list-1');
      expect(item.name, 'Apples');
      expect(item.quantity, const Quantity(2500));
      expect(item.unit, 'kg');
      expect(item.unitPrice, const Money(300));
      expect(item.isBought, isTrue);
      expect(item.createdAt, now);
      expect(item.updatedAt, now);
    });

    test('FR-080 toListDetailEntity maps ListDetailRow to ListDetail', () {
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final listRow = ShoppingListRow(
        id: 'list-1',
        name: 'Groceries',
        currencyCode: 'USD',
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );
      final itemRow = ShoppingItemRow(
        id: 'item-1',
        listId: 'list-1',
        name: 'Milk',
        quantityMilli: 1000,
        unit: 'l',
        unitPriceMinor: 250,
        isBought: false,
        createdAt: now.millisecondsSinceEpoch,
        updatedAt: now.millisecondsSinceEpoch,
      );

      final detailRow = ListDetailRow(list: listRow, items: [itemRow]);
      final detail = mapper.toListDetailEntity(detailRow);

      expect(detail.list.id, 'list-1');
      expect(detail.list.currency, CurrencyCode.usd);
      expect(detail.items.length, 1);
      expect(detail.items.first.name, 'Milk');
    });

    test('FR-080 toInsertCompanion creates insert companion from draft', () {
      const draft = ItemDraft(
        name: 'Bread',
        quantity: Quantity(2000),
        unit: 'loaves',
        unitPrice: Money(150),
      );

      final companion = mapper.toInsertCompanion(
        id: 'item-new',
        listId: 'list-1',
        draft: draft,
        createdAt: 1000,
        updatedAt: 1000,
        isBought: true,
      );

      expect(companion.id.value, 'item-new');
      expect(companion.listId.value, 'list-1');
      expect(companion.name.value, 'Bread');
      expect(companion.quantityMilli.value, 2000);
      expect(companion.unit.value, 'loaves');
      expect(companion.unitPriceMinor.value, 150);
      expect(companion.isBought.value, isTrue);
      expect(companion.createdAt.value, 1000);
      expect(companion.updatedAt.value, 1000);
    });

    test('FR-080 toUpdateCompanion creates update companion from draft', () {
      const draft = ItemDraft(
        name: 'Whole Bread',
        quantity: Quantity(3000),
        unit: null,
        unitPrice: Money(200),
      );

      final companion = mapper.toUpdateCompanion(
        id: 'item-1',
        draft: draft,
        updatedAt: 2000,
      );

      expect(companion.id.value, 'item-1');
      expect(companion.name.value, 'Whole Bread');
      expect(companion.quantityMilli.value, 3000);
      expect(companion.unit.value, isNull);
      expect(companion.unitPriceMinor.value, 200);
      expect(companion.updatedAt.value, 2000);
    });
  });
}
