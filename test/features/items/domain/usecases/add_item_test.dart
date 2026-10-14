import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/add_item.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late AddItem useCase;

  setUpAll(() {
    registerFallbackValue(const ItemDraft(
      name: 'Fallback',
      quantity: Quantity(1000),
      unitPrice: Money.zero,
    ));
  });

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = AddItem(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final draft = const ItemDraft(
    name: 'Tomatoes',
    quantity: Quantity.fromMilli(2500),
    unit: 'kg',
    unitPrice: Money.fromMinor(150000),
  );
  final addedItem = ShoppingItem(
    id: 'item-1',
    listId: 'list-1',
    name: 'Tomatoes',
    quantity: const Quantity.fromMilli(2500),
    unit: 'kg',
    unitPrice: const Money.fromMinor(150000),
    isBought: false,
    createdAt: now,
    updatedAt: now,
  );

  group('AddItem', () {
    test('FR-010 adds item successfully when list is below 500 limit', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Right(499));
      when(() => repository.addItem(
            listId: 'list-1',
            draft: draft,
          )).thenAnswer((_) async => Right(addedItem));

      final result = await useCase(AddItemParams(
        listId: 'list-1',
        draft: draft,
      ));

      expect(result, Right(addedItem));
      expect(AddItemParams(listId: 'list-1', draft: draft).props, ['list-1', draft]);
      verify(() => repository.addItem(
            listId: 'list-1',
            draft: draft,
          )).called(1);
    });

    test('FR-011 returns LimitFailure when list already has 500 items', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Right(AppLimits.maxItemsPerList));

      final result = await useCase(AddItemParams(
        listId: 'list-1',
        draft: draft,
      ));

      expect(result, const Left(LimitFailure(LimitKind.items)));
      verifyNever(() => repository.addItem(
            listId: any(named: 'listId'),
            draft: any(named: 'draft'),
          ));
    });

    test('FR-010 returns Failure when repository itemCount fails', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(AddItemParams(
        listId: 'list-1',
        draft: draft,
      ));

      expect(result, const Left(DatabaseFailure('DB error')));
    });

    test('FR-010 returns Failure when repository addItem fails', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Right(10));
      when(() => repository.addItem(
            listId: 'list-1',
            draft: draft,
          )).thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(AddItemParams(
        listId: 'list-1',
        draft: draft,
      ));

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
