import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/set_item_bought.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late SetItemBought useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = SetItemBought(repository);
  });

  group('SetItemBought', () {
    test('FR-016 updates bought status successfully', () async {
      when(() => repository.setBought(
            id: 'item-1',
            isBought: true,
          )).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const SetItemBoughtParams(
        itemId: 'item-1',
        isBought: true,
      ));

      expect(result, const Right(unit));
      verify(() => repository.setBought(
            id: 'item-1',
            isBought: true,
          )).called(1);
    });

    test('FR-016 returns NotFoundFailure when item does not exist', () async {
      when(() => repository.setBought(
            id: 'missing-item',
            isBought: false,
          )).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(const SetItemBoughtParams(
        itemId: 'missing-item',
        isBought: false,
      ));

      expect(result, const Left(NotFoundFailure()));
      expect(const SetItemBoughtParams(itemId: 'missing-item', isBought: false).props, ['missing-item', false]);
    });
  });
}
