import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/delete_item.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late DeleteItem useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = DeleteItem(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final deletedItem = ShoppingItem(
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

  group('DeleteItem', () {
    test('FR-015 deletes item and returns deleted ShoppingItem for undo', () async {
      when(() => repository.deleteItem('item-1'))
          .thenAnswer((_) async => Right(deletedItem));

      final result = await useCase('item-1');

      expect(result, Right(deletedItem));
      verify(() => repository.deleteItem('item-1')).called(1);
    });

    test('FR-015 returns NotFoundFailure when item does not exist', () async {
      when(() => repository.deleteItem('item-1'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase('item-1');

      expect(result, const Left(NotFoundFailure()));
    });
  });
}
