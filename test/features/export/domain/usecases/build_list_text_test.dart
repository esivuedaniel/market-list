import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/features/export/domain/usecases/build_list_text.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

class FakeClock extends Clock {
  const FakeClock(this._fixedTime);

  final DateTime _fixedTime;

  @override
  DateTime now() => _fixedTime;

  @override
  int nowEpochMs() => _fixedTime.millisecondsSinceEpoch;
}

void main() {
  late MockShoppingItemRepository itemRepository;
  late BuildListText useCase;
  final fixedDate = DateTime.utc(2026, 10, 12);

  setUp(() {
    itemRepository = MockShoppingItemRepository();
    useCase = BuildListText(
      itemRepository: itemRepository,
      clock: FakeClock(fixedDate),
    );
  });

  final list = ShoppingList(
    id: 'l1',
    name: 'Sunday market',
    currency: CurrencyCode.ngn,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  );

  group('BuildListText', () {
    test('FR-072 returns ValidationFailure when list is empty', () async {
      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => Right(ListDetail(list: list, items: const [])));

      final result = await useCase('l1');

      expect(result, const Left(ValidationFailure('Cannot export an empty list.')));
    });

    test('FR-071 matches PRD 11.6 plain text export format with and without units', () async {
      final items = [
        ShoppingItem(
          id: '1',
          listId: 'l1',
          name: 'Tomatoes',
          quantity: const Quantity.fromMilli(2500),
          unit: 'kg',
          unitPrice: const Money.fromMinor(150000), // 3,750.00
          isBought: false,
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
        ShoppingItem(
          id: '2',
          listId: 'l1',
          name: 'Onions',
          quantity: const Quantity.fromMilli(3000),
          unit: 'pcs',
          unitPrice: const Money.fromMinor(20000), // 600.00
          isBought: true,
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
        ShoppingItem(
          id: '3',
          listId: 'l1',
          name: 'Rice',
          quantity: const Quantity.fromMilli(1000),
          unit: 'bag',
          unitPrice: const Money.fromMinor(4500000), // 45,000.00
          isBought: false,
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      ];
      final detail = ListDetail(list: list, items: items);

      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => Right(detail));

      final result = await useCase('l1');

      final expectedText = [
        'Sunday market',
        '12 Oct 2026',
        '',
        '1. Tomatoes, 2.5 kg x 1,500.00 = 3,750.00',
        '2. Onions, 3 pcs x 200.00 = 600.00',
        '3. Rice, 1 bag x 45,000.00 = 45,000.00',
        '',
        'Total: ₦49,350.00',
      ].join('\n');

      expect(result, Right(expectedText));
    });

    test('FR-071 omits unit when unit is null', () async {
      final items = [
        ShoppingItem(
          id: '1',
          listId: 'l1',
          name: 'Tomatoes',
          quantity: const Quantity.fromMilli(2500),
          unit: null,
          unitPrice: const Money.fromMinor(150000),
          isBought: false,
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      ];
      final detail = ListDetail(list: list, items: items);

      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => Right(detail));

      final result = await useCase('l1');

      final expectedText = [
        'Sunday market',
        '12 Oct 2026',
        '',
        '1. Tomatoes, 2.5 x 1,500.00 = 3,750.00',
        '',
        'Total: ₦3,750.00',
      ].join('\n');

      expect(result, Right(expectedText));
    });
  });
}
