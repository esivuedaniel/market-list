import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/get_item.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late GetItem useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = GetItem(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final item = ShoppingItem(
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

  group('GetItem', () {
    test('FR-014 returns ShoppingItem when found', () async {
      when(() => repository.getItem('item-1'))
          .thenAnswer((_) async => Right(item));

      final result = await useCase('item-1');

      expect(result, Right(item));
      verify(() => repository.getItem('item-1')).called(1);
    });

    test('FR-014 returns NotFoundFailure when item not found', () async {
      when(() => repository.getItem('missing'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase('missing');

      expect(result, const Left(NotFoundFailure()));
    });
  });
}
