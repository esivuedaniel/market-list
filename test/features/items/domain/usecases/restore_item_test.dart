import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/restore_item.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late RestoreItem useCase;

  setUpAll(() {
    registerFallbackValue(ShoppingItem(
      id: 'fallback',
      listId: 'fallback',
      name: 'Fallback',
      quantity: const Quantity(1000),
      unit: null,
      unitPrice: Money.zero,
      isBought: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ));
  });

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = RestoreItem(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final itemToRestore = ShoppingItem(
    id: 'item-1',
    listId: 'list-1',
    name: 'Tomatoes',
    quantity: const Quantity(2500),
    unit: 'kg',
    unitPrice: const Money(150000),
    isBought: false,
    createdAt: now,
    updatedAt: now,
  );

  group('RestoreItem', () {
    test('FR-012 restores item successfully when list is below 500 items', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Right(499));
      when(() => repository.restoreItem(itemToRestore))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase(itemToRestore);

      expect(result, const Right(unit));
      verify(() => repository.restoreItem(itemToRestore)).called(1);
    });

    test('FR-013 RestoreItem fails at 500 items with LimitFailure', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Right(AppLimits.maxItemsPerList));

      final result = await useCase(itemToRestore);

      expect(result, const Left(LimitFailure(LimitKind.items)));
      verifyNever(() => repository.restoreItem(any()));
    });

    test('FR-013 returns Failure when repository itemCount fails', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(itemToRestore);

      expect(result, const Left(DatabaseFailure('DB error')));
    });

    test('FR-012 returns Failure when repository restoreItem fails', () async {
      when(() => repository.itemCount('list-1'))
          .thenAnswer((_) async => const Right(10));
      when(() => repository.restoreItem(itemToRestore))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(itemToRestore);

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
