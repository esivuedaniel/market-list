import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/update_item.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late UpdateItem useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = UpdateItem(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  const draft = ItemDraft(
    name: 'Tomatoes',
    quantity: Quantity(3000),
    unit: 'kg',
    unitPrice: Money(160000),
  );
  final updatedItem = ShoppingItem(
    id: 'item-1',
    listId: 'list-1',
    name: 'Tomatoes',
    quantity: const Quantity(3000),
    unit: 'kg',
    unitPrice: const Money(160000),
    isBought: false,
    createdAt: now,
    updatedAt: now,
  );

  group('UpdateItem', () {
    test('FR-014 updates item successfully', () async {
      when(() => repository.updateItem(
            id: 'item-1',
            draft: draft,
          )).thenAnswer((_) async => Right(updatedItem));

      final result = await useCase(const UpdateItemParams(
        itemId: 'item-1',
        draft: draft,
      ));

      expect(result, Right(updatedItem));
      verify(() => repository.updateItem(
            id: 'item-1',
            draft: draft,
          )).called(1);
    });

    test('FR-014 returns NotFoundFailure when item does not exist', () async {
      when(() => repository.updateItem(
            id: 'item-1',
            draft: draft,
          )).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(const UpdateItemParams(
        itemId: 'item-1',
        draft: draft,
      ));

      expect(result, const Left(NotFoundFailure()));
      expect(const UpdateItemParams(itemId: 'item-1', draft: draft).props, ['item-1', draft]);
    });
  });
}
