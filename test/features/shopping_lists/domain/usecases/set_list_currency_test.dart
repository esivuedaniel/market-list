import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/set_list_currency.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late SetListCurrency useCase;

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = SetListCurrency(repository);
  });

  group('SetListCurrency', () {
    test('FR-006 updates list currency without converting amounts', () async {
      when(() => repository.setCurrency(
            id: 'list-1',
            currency: CurrencyCode.eur,
          )).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const SetListCurrencyParams(
        listId: 'list-1',
        currency: CurrencyCode.eur,
      ));

      expect(result, const Right(unit));
      verify(() => repository.setCurrency(
            id: 'list-1',
            currency: CurrencyCode.eur,
          )).called(1);
    });

    test('FR-006 returns NotFoundFailure when list does not exist', () async {
      when(() => repository.setCurrency(
            id: 'missing-list',
            currency: CurrencyCode.eur,
          )).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(const SetListCurrencyParams(
        listId: 'missing-list',
        currency: CurrencyCode.eur,
      ));

      expect(result, const Left(NotFoundFailure()));
      expect(const SetListCurrencyParams(listId: 'missing-list', currency: CurrencyCode.eur).props, ['missing-list', CurrencyCode.eur]);
    });
  });
}
